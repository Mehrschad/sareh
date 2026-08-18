// گذارِ صفحه — ۳۴۰ میلی‌ثانیه با منحنیِ «کمانِ آرش» (بخش ۷٫۲).
//
// صفحه از سمتِ راست می‌آید، چون جهتِ خواندن راست‌به‌چپ است و صفحه‌ی تازه باید
// از همان‌جا وارد شود که چشم می‌رود.

import 'package:flutter/material.dart';

import '../design/tokens.g.dart';

class SarehPageTransition {
  const SarehPageTransition._();

  static Duration get duration => SarehMotion.page;

  static Widget build(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: SarehMotion.pageCurve,
      reverseCurve: SarehMotion.microCurve,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.06, 0),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(opacity: curved, child: child),
    );
  }
}
