import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/wishlist_provider.dart';
import 'repositories/book_repository.dart';
import 'features/checkout/checkout_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        Provider<BookRepository>(create: (_) => DummyBookRepository()),
        ChangeNotifierProvider(create: (_) => WishlistProvider(prefs)),
        Provider<CheckoutRepository>(
          create: (ctx) => DummyCheckoutRepository(ctx.read<BookRepository>()),
        ),
        // Tiap orang boleh menambah provider miliknya di sini lewat PR kecil.
      ],
      child: const NestallaApp(),
    ),
  );
}

class NestallaApp extends StatelessWidget {
  const NestallaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Nestalla',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
