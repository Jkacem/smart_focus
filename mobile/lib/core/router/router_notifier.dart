import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../network/app_dio.dart';
import 'app_routes.dart';

// Routes that do not require authentication.
const _publicRoutes = {
  AppRoutes.welcome,
  AppRoutes.authOptions,
  AppRoutes.login,
  AppRoutes.register,
};

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
    _ref.listen<int>(unauthorizedEventProvider, (_, __) {
      _ref.read(authProvider.notifier).logout();
    });
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authProvider);

    // Still checking the stored token — don't redirect yet.
    if (auth.isInitializing) return null;

    final isPublic = _publicRoutes.contains(state.matchedLocation);

    if (!auth.isAuthenticated && !isPublic) return AppRoutes.welcome;
    if (auth.isAuthenticated && isPublic) return AppRoutes.dashboard;
    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});
