import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/back_button.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _Faq {
  final int number;
  final String question;
  final String answer;

  const _Faq({
    required this.number,
    required this.question,
    required this.answer,
  });
}

class _FaqPageState extends State<FaqPage> {
  static const _faqs = [
    _Faq(
      number: 1,
      question: 'Bagaimana cara membuat akun?',
      answer: 'Ketuk Daftar di halaman login, lalu isi nama lengkap, username, email, dan kata sandi (minimal 6 karakter). Setelah berhasil, kamu bisa langsung masuk dengan username atau email yang didaftarkan.',
    ),
    _Faq(
      number: 2,
      question: 'Saya lupa kata sandi. Apa yang harus dilakukan?',
      answer: 'Ketuk Lupa kata sandi? di halaman login, lalu ikuti langkah pemulihan lewat email yang terdaftar. Kalau kamu masih bisa masuk, kamu juga bisa mengubahnya lewat Akun \u2192 Ubah Kata Sandi.',
    ),
    _Faq(
      number: 3,
      question: 'Bagaimana cara mengubah data profil?',
      answer: 'Buka Akun \u2192 Profil Saya. Di sana kamu bisa mengubah nama lengkap, nomor telepon, dan tanggal lahir. Email tidak dapat diubah karena dipakai sebagai identitas akun.',
    ),
    _Faq(
      number: 4,
      question: 'Bagaimana cara membeli buku?',
      answer: 'Buka halaman detail buku, lalu ketuk Add to cart. Di Keranjang, centang buku yang ingin dibeli, atur jumlahnya, lalu ketuk Checkout. Isi alamat pengiriman dan pilih metode pembayaran untuk menyelesaikan pesanan.',
    ),
    _Faq(
      number: 5,
      question: 'Apa fungsi menu Favorit?',
      answer: 'Favorit menyimpan buku yang kamu minati tanpa harus membelinya sekarang. Ketuk ikon hati di buku untuk menambah atau menghapusnya. Semua buku favorit ada di tab Favorit, dan bisa disaring berdasarkan kategori.',
    ),
    _Faq(
      number: 6,
      question: 'Metode pembayaran apa saja yang tersedia?',
      answer: 'Kami menerima transfer bank, dompet digital (e-wallet), bayar di tempat (COD), dan kartu kredit. Metode dipilih saat checkout.',
    ),
    _Faq(
      number: 7,
      question: 'Bagaimana cara melihat status pesanan saya?',
      answer: 'Buka tab Pesanan, lalu ketuk pesanan yang ingin dilihat. Status pesanan berurutan: Menunggu, Diproses, Dikirim, dan Selesai. Pesanan yang dibatalkan ditandai Dibatalkan.',
    ),
    _Faq(
      number: 8,
      question: 'Bagaimana cara menggunakan kode promo?',
      answer: 'Masukkan kode promo saat checkout. Potongan harga atau gratis ongkir akan otomatis terhitung bila kodenya masih berlaku dan syarat promonya terpenuhi. Kalau kode ditolak, periksa penulisannya dan masa berlakunya.',
    ),
  ];

  final List<bool> _expanded = List.generate(8, (_) => false);

  Widget _buildFaqItem(int index) {
    final faq = _faqs[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded[index] = !_expanded[index]),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${faq.number}. ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    faq.question,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _expanded[index]
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.navy,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _expanded[index]
              ? Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 16,
                    bottom: 12,
                  ),
                  child: Text(
                    faq.answer,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.dark,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        if (index < _faqs.length - 1)
          const Divider(height: 1, color: AppColors.grey),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    AppBackButton(onPressed: () => context.pop()),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Pertanyaan Umum',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 52),
                  ],
                ),
                const SizedBox(height: 24),
                ...List.generate(_faqs.length, _buildFaqItem),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
