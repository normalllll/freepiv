import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Page<void> detailTransitionPage({required LocalKey key, required Widget child}) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.025), end: Offset.zero).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}
