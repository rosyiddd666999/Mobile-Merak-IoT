import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'data/providers/auth_provider.dart';
import 'shared/app_bottom_nav.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/incubator/incubator_screen.dart';
import 'features/incubator/settings_screen.dart';
import 'features/breeders/breeders_list_screen.dart';
import 'features/breeders/breeder_detail_screen.dart';
import 'features/breeders/breeder_form_screen.dart';
import 'features/eggs/eggs_list_screen.dart';
import 'features/eggs/egg_detail_screen.dart';
import 'features/eggs/egg_form_screen.dart';
import 'features/chicks/chicks_list_screen.dart';
import 'features/chicks/chick_detail_screen.dart';
import 'features/chicks/chick_form_screen.dart';
import 'features/sales/sales_list_screen.dart';
import 'features/sales/sale_detail_screen.dart';
import 'features/sales/sale_form_screen.dart';
import 'features/finance/finance_list_screen.dart';
import 'features/finance/finance_detail_screen.dart';
import 'features/finance/finance_form_screen.dart';
import 'features/users/users_list_screen.dart';
import 'features/users/user_detail_screen.dart';
import 'features/users/user_form_screen.dart';
import 'features/alerts/alerts_list_screen.dart';
import 'features/cctv/cctv_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/about/about_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Jembatan stream Riverpod -> Listenable agar GoRouter bereaksi terhadap
/// perubahan auth (login/logout/401) tanpa perlu pindah rute manual.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream();

  /// Panggil saat state auth berubah agar router evaluasi ulang redirect.
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  // Pernah login di sesi ini — untuk bedakan "belum login" vs "sesi berakhir".
  var wasLoggedIn = ref.read(authProvider).valueOrNull != null;
  final refresh = GoRouterRefreshStream();
  ref.onDispose(refresh.dispose);
  ref.listen(authProvider, (_, _) => refresh.ping());
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider).valueOrNull;
      final isLoggedIn = auth != null;
      if (isLoggedIn) wasLoggedIn = true;
      final loc = state.matchedLocation;
      final isLoginRoute = loc == '/login';
      final isSplash = loc == '/';

      if (isSplash) return null;
      if (!isLoggedIn && !isLoginRoute) {
        // Sesi berakhir (dulu login) -> tandai agar login tampilkan pesan khusus.
        return wasLoggedIn ? '/login?expired=1' : '/login';
      }
      if (isLoggedIn && isLoginRoute) return '/dashboard';
      // Tab Keuangan (index terakhir) khusus pemilik — disembunyikan untuk role lain.
      if (isLoggedIn && loc.startsWith('/finance')) {
        final user = ref.read(currentUserProvider);
        if (user?.role != 'pemilik') return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/incubator', builder: (_, _) => const IncubatorScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/breeders', builder: (_, _) => const BreedersListScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/eggs', builder: (_, _) => const EggsListScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/finance', builder: (_, _) => const FinanceListScreen())],
          ),
        ],
      ),

      GoRoute(path: '/incubator/settings', parentNavigatorKey: _rootNavigatorKey, builder: (_, _) => const IncubatorSettingsScreen()),
      GoRoute(path: '/breeders/new', parentNavigatorKey: _rootNavigatorKey, builder: (_, _) => const BreederFormScreen()),
      GoRoute(
        path: '/breeders/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => BreederFormScreen(editId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/breeders/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => BreederDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/eggs/new', parentNavigatorKey: _rootNavigatorKey, builder: (_, _) => const EggFormScreen()),
      GoRoute(
        path: '/eggs/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => EggFormScreen(editId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/eggs/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => EggDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/chicks', parentNavigatorKey: _rootNavigatorKey, builder: (_, _) => const ChicksListScreen()),
      GoRoute(path: '/chicks/new', parentNavigatorKey: _rootNavigatorKey, builder: (_, _) => const ChickFormScreen()),
      GoRoute(
        path: '/chicks/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => ChickFormScreen(editId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/chicks/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => ChickDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/sales', parentNavigatorKey: _rootNavigatorKey, builder: (_, _) => const SalesListScreen()),
      GoRoute(
        path: '/sales/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => SaleFormScreen(
          initialItem: state.uri.queryParameters['item'],
          initialRef: state.uri.queryParameters['ref'],
        ),
      ),
      GoRoute(
        path: '/sales/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => SaleDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/finance/new', parentNavigatorKey: _rootNavigatorKey, builder: (_, _) => const FinanceFormScreen()),
      GoRoute(
        path: '/finance/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => FinanceDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/alerts', parentNavigatorKey: _rootNavigatorKey, builder: (_, _) => const AlertsListScreen()),
      GoRoute(path: '/users', parentNavigatorKey: _rootNavigatorKey, builder: (_, _) => const UsersListScreen()),
      GoRoute(path: '/users/new', parentNavigatorKey: _rootNavigatorKey, builder: (_, _) => const UserFormScreen()),
      GoRoute(
        path: '/users/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => UserDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/cctv', parentNavigatorKey: _rootNavigatorKey, builder: (_, _) => const CctvScreen()),
      GoRoute(path: '/profile', parentNavigatorKey: _rootNavigatorKey, builder: (_, _) => const ProfileScreen()),
      GoRoute(path: '/about', parentNavigatorKey: _rootNavigatorKey, builder: (_, _) => const AboutScreen()),
    ],
  );
});

class _ShellScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const _ShellScaffold({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isLoggedIn = auth.valueOrNull != null;
    final user = ref.watch(currentUserProvider);
    final isPemilik = user?.role == 'pemilik';

    return Scaffold(
      appBar: null,
      body: navigationShell,
      bottomNavigationBar:
          isLoggedIn
              ? AppBottomNav(
                  currentIndex: navigationShell.currentIndex,
                  onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
                  isPemilik: isPemilik,
                )
              : null,
    );
  }
}
