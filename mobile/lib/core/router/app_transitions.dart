import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppTransitions {
  const AppTransitions._();

  static const Duration _forwardDuration = Duration(milliseconds: 320);
  static const Duration _reverseDuration = Duration(milliseconds: 260);

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final slide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }

  static CustomTransitionPage<T> page<T>({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: _forwardDuration,
      reverseTransitionDuration: _reverseDuration,
      transitionsBuilder: _buildTransition,
    );
  }

  static PageRouteBuilder<T> route<T>({
    required Widget child,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: _forwardDuration,
      reverseTransitionDuration: _reverseDuration,
      transitionsBuilder: _buildTransition,
    );
  }
}
