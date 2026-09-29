import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/shared/ui/fp_page_transition.dart';
import 'package:go_router/go_router.dart';

/// [heroLed] pages receive a flying artwork; their own motion is halved.
Page<void> detailTransitionPage({required LocalKey key, required Widget child, bool heroLed = false}) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: AppMotion.page,
    reverseTransitionDuration: AppMotion.exit,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) => fpPageTransition(context, animation, secondaryAnimation, child, heroLed: heroLed),
  );
}
