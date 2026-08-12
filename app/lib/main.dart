// سره — نقطه‌ی آغاز.
//
// آفلاین‌اول، بی‌استثنا: اپ بدون اینترنت کامل کار می‌کند و حسابِ کاربری
// اختیاری است. هیچ تحلیل‌گرِ شخصِ ثالثی اینجا نیست و نخواهد بود (بخش ۹٫۴).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'core/transitions.dart';
import 'design/widgets.dart';
import 'features/journey/journey_page.dart';
import 'features/lesson/lesson_page.dart';

void main() {
  runApp(const ProviderScope(child: SarehApp()));
}

/// تنظیماتی که کاربر خودش برمی‌گزیند و اپ باید بی‌درنگ به آنها تن بدهد.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.textScale = 1.0,
    this.reducedMotion = false,
    this.dyslexic = false,
  });

  /// پس‌زمینه‌ی تیره پیش‌فرض است — مثل شبستانِ مسجد که نور از کاشی می‌تابد.
  final ThemeMode themeMode;
  final double textScale;
  final bool reducedMotion;
  final bool dyslexic;

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? textScale,
    bool? reducedMotion,
    bool? dyslexic,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        textScale: textScale ?? this.textScale,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        dyslexic: dyslexic ?? this.dyslexic,
      );
}

final settingsProvider =
    StateProvider<AppSettings>((ref) => const AppSettings());

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const JourneyPage(),
        routes: [
          GoRoute(
            path: 'lesson/:stationId',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: LessonPage(stationId: state.pathParameters['stationId']!),
              transitionDuration: SarehPageTransition.duration,
              transitionsBuilder: SarehPageTransition.build,
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: SarehEmpty(message: 'این راه به جایی نمی‌رسد.\n${state.uri}'),
    ),
  );
});

class SarehApp extends ConsumerWidget {
  const SarehApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: 'سره',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: SarehThemeData.light(dyslexic: settings.dyslexic),
      darkTheme: SarehThemeData.dark(dyslexic: settings.dyslexic),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => SarehShell(
        textScale: settings.textScale,
        reducedMotion: settings.reducedMotion,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
