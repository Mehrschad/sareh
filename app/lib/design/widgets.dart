// ویجت‌های پایه‌ی سامانه‌ی طراحی.
//
// هر مقدارِ رنگ، فاصله، شعاع و زمان از `tokens.g.dart` می‌آید. اگر عددی اینجا
// هارد‌کد شود، CI آن را می‌گیرد (بخش ۹٫۴).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'nur_e_vajeh.dart' show SarehTheme;
import 'tokens.g.dart';

extension SarehThemeAccess on BuildContext {
  SarehColors get colors => Theme.of(this).extension<SarehTheme>()!.colors;
  bool get reducedMotion => MediaQuery.of(this).disableAnimations;
}

/// اعداد پیش‌فرض پارسی‌اند (بخش ۳٫۲).
String toPersianDigits(Object value) {
  const digits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  return value.toString().replaceAllMapped(
        RegExp(r'\d'),
        (m) => digits[int.parse(m[0]!)],
      );
}

/// دکمه‌ی کپسولیِ کنشِ اصلی.
///
/// هنگام فشرده‌شدن، وزنِ قلمِ متغیر از ۴۰۰ به ۷۰۰ می‌رود و دکمه کمی جمع می‌شود
/// — ۱۲۰ میلی‌ثانیه با منحنیِ `kamanTiz` (بخش ۳٫۲ و ۷٫۲).
class SarehButton extends StatefulWidget {
  const SarehButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.emphasis = SarehEmphasis.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final SarehEmphasis emphasis;
  final Widget? icon;

  @override
  State<SarehButton> createState() => _SarehButtonState();
}

enum SarehEmphasis { primary, quiet }

class _SarehButtonState extends State<SarehButton> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = widget.onPressed != null;
    final primary = widget.emphasis == SarehEmphasis.primary;

    final background = primary ? colors.action : Colors.transparent;
    final foreground = primary ? colors.onAction : colors.onSurface;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => _setDown(true) : null,
        onTapUp: enabled ? (_) => _setDown(false) : null,
        onTapCancel: enabled ? () => _setDown(false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!.call();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1.0,
          duration: SarehMotion.micro,
          curve: SarehMotion.microCurve,
          child: AnimatedContainer(
            duration: SarehMotion.micro,
            curve: SarehMotion.microCurve,
            constraints: const BoxConstraints(minHeight: SarehA11y.minTouchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: SarehSpace.lg,
              vertical: SarehSpace.sm,
            ),
            decoration: BoxDecoration(
              color: enabled ? background : background.withValues(alpha: SarehOpacity.disabled),
              borderRadius: BorderRadius.circular(SarehRadius.capsule),
              border: primary ? null : Border.all(color: colors.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon case final icon?) ...[
                  icon,
                  const SizedBox(width: SarehSpace.sm),
                ],
                AnimatedDefaultTextStyle(
                  duration: SarehMotion.micro,
                  curve: SarehMotion.microCurve,
                  style: TextStyle(
                    fontFamily: SarehType.bodyFamily,
                    fontSize: SarehType.md,
                    height: SarehType.mdLine,
                    // محورِ وزنِ متغیر: ۴۰۰ → ۷۰۰ هنگامِ فشردن.
                    fontWeight: _down ? FontWeight.w700 : FontWeight.w400,
                    color: enabled ? foreground : foreground.withValues(alpha: SarehOpacity.disabled),
                  ),
                  child: Text(widget.label, textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// کارتِ سطحِ برجسته. شعاعِ گوشه ۲۰.
class SarehCard extends StatelessWidget {
  const SarehCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SarehSpace.md),
    this.borderColour,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColour;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(SarehRadius.card),
        border: Border.all(color: borderColour ?? colors.outline),
      ),
      child: child,
    );
  }
}

/// نوارِ پیشرفت با کششِ فنری (بخش ۷٫۳).
///
/// `SpringSimulation` را با همان سختی و میرایی توکن‌ها می‌بندد، پس پرشدنش
/// کمی از هدف می‌گذرد و برمی‌گردد — مثلِ کششِ زهِ کمان.
class SarehProgressBar extends StatefulWidget {
  const SarehProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.semanticLabel,
  });

  /// میان ۰ و ۱.
  final double value;
  final double height;
  final String? semanticLabel;

  @override
  State<SarehProgressBar> createState() => _SarehProgressBarState();
}

class _SarehProgressBarState extends State<SarehProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController.unbounded(vsync: this)
    ..value = widget.value;

  @override
  void didUpdateWidget(covariant SarehProgressBar old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = widget.value;
      return;
    }
    _controller.animateWith(
      SpringSimulation(
        const SpringDescription(
          mass: SarehMotion.springMass,
          stiffness: SarehMotion.springStiffness,
          damping: SarehMotion.springDamping,
        ),
        _controller.value,
        widget.value,
        0,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: widget.semanticLabel,
      value: '${toPersianDigits((widget.value * 100).round())}٪',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SarehRadius.capsule),
        child: SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => LinearProgressIndicator(
              value: _controller.value.clamp(0.0, 1.0),
              backgroundColor: colors.surfaceRaised,
              valueColor: AlwaysStoppedAnimation<Color>(colors.action),
            ),
          ),
        ),
      ),
    );
  }
}

/// لرزشِ افقی برای پاسخِ نادرست: ۸ پیکسل، سه رفت‌وبرگشت، ۳۰۰ms.
///
/// بدونِ صدای تنبیهی و بدونِ قرمزکردنِ صفحه (بخش ۷٫۳).
class SarehShake extends StatefulWidget {
  const SarehShake({super.key, required this.trigger, required this.child});

  /// هر بار که این مقدار عوض شود، یک لرزش رخ می‌دهد.
  final int trigger;
  final Widget child;

  @override
  State<SarehShake> createState() => _SarehShakeState();
}

class _SarehShakeState extends State<SarehShake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SarehMotion.shake,
  );

  @override
  void didUpdateWidget(covariant SarehShake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !MediaQuery.of(context).disableAnimations) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (!_controller.isAnimating) return child!;
          final decay = 1 - _controller.value;
          final dx = math.sin(_controller.value * math.pi * 2 * SarehMotion.shakeCycles) *
              SarehMotion.shakeAmplitude *
              decay;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: widget.child,
      );
}

/// صفحه‌ی خالی. هرگز «هیچ داده‌ای موجود نیست» (بخش ۱۴).
class SarehEmpty extends StatelessWidget {
  const SarehEmpty({super.key, required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(SarehSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: SarehType.bodyFamily,
                  fontSize: SarehType.lg,
                  height: SarehType.lgLine,
                  color: context.colors.onSurfaceMuted,
                ),
              ),
              if (action case final action?) ...[
                const SizedBox(height: SarehSpace.lg),
                action,
              ],
            ],
          ),
        ),
      );
}
