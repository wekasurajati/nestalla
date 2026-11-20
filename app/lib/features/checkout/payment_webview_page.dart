import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../widgets/back_button.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String redirectUrl;

  const PaymentWebViewPage({super.key, required this.redirectUrl});

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  void _showCloseDialog() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Tutup halaman pembayaran?'),
        content: const Text('Pesanan tetap menunggu pembayaran.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tutup'),
          ),
        ],
      ),
    ).then((result) {
      if (result == true && mounted) {
        Navigator.pop(context, false);
      }
    });
  }

  void _reload() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _controller.loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Gagal memuat halaman pembayaran';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;

            // Arahkan ke halaman finish pembayaran
            if (url.startsWith(ApiConfig.paymentFinishUrl)) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }

            // Skema non-http(s) (misal e-wallet app link)
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              // TODO: buka aplikasi e-wallet yang sesuai
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _showCloseDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: AppBackButton(
            onPressed: () => _showCloseDialog(),
          ),
          title: const Text(
            'Pembayaran',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        body: _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.navy,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _reload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          shape: AppRadius.shape,
                        ),
                        child: const Text(
                          'Coba Lagi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading)
                    const LinearProgressIndicator(),
                ],
              ),
      ),
    );
  }
}
