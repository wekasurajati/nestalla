import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'repositories/book_repository.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<BookRepository>(create: (_) => DummyBookRepository()),
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