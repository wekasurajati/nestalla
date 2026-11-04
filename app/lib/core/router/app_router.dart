import 'package:go_router/go_router.dart';

import '../../widgets/main_shell.dart';
import '../../widgets/placeholder_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/book_detail/book_detail_page.dart';
import '../../features/profile/my_account_page.dart';
import '../../features/wishlist/wishlist_page.dart';
import '../../features/auth/forgot_password_page.dart';
import '../../features/orders/my_order_page.dart';
import '../../features/checkout/checkout_page.dart';

// Pemilik page: ganti PlaceholderPage dengan page asli kalian.
final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    // --- Orang A: auth ---
    GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
    GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
    GoRoute(
      path: '/forgot-password',
      builder: (_, _) => const ForgotPasswordPage(),
    ),

    // --- Halaman dengan bottom navbar ---
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const PlaceholderPage('Home'),
            ), // B
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/orders',
              builder: (_, _) => const MyOrderPage(),
            ), // D
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/wishlist',
              builder: (_, _) => const WishlistPage(),
            ), // C
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const MyAccountPage(),
            ), // A // A
          ],
        ),
      ],
    ),

    // --- Halaman tanpa navbar ---
    GoRoute(
      path: '/search',
      builder: (_, _) => const PlaceholderPage('Search'),
    ), // B
    GoRoute(
      path: '/notifications',
      builder: (_, _) => const PlaceholderPage('Notifications'),
    ), // B
    GoRoute(
      path: '/book/:id',
      builder: (_, s) => BookDetailPage(
        bookId: int.tryParse(s.pathParameters['id'] ?? ''),
      ), // C
    ),
    GoRoute(
      path: '/cart',
      builder: (_, _) => const PlaceholderPage('Cart'),
    ), // C
    GoRoute(
      path: '/checkout',
      builder: (_, _) => const CheckoutPage(),
    ), // D
    GoRoute(
      path: '/orders/:id',
      builder: (_, s) =>
          PlaceholderPage('Order Detail ${s.pathParameters['id']}'), // D
    ),
  ],
);
