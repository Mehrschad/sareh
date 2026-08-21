// تنظیماتِ کاربر — با ماندگاری.
//
// پیش‌تر تنظیمات یک StateProvider درون‌حافظه بود: هر بستنِ اپ، انتخابِ
// کاربر را دور می‌ریخت. حالا از جدولِ `settings` خوانده و به آن نوشته
// می‌شود؛ کلید/مقدار، پس افزودنِ تنظیمِ تازه مهاجرت نمی‌خواهد.
//
// «onboarded» هم اینجاست: سه‌حالتی است، نه دوحالتی. `null` یعنی هنوز از
// دیسک نخوانده‌ایم — و تا ندانیم، صفحه‌ی خوشامد را نشان نمی‌دهیم؛ وگرنه
// کاربرِ قدیمی در هر باز کردنِ اپ یک پرشِ کوتاه به خوشامد می‌دید.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/progress_repository.dart';
import '../features/journey/progress.dart';
import 'sound.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.textScale = 1.0,
    this.reducedMotion = false,
    this.dyslexic = false,
    this.sound = true,
    this.onboarded,
  });

  /// پس‌زمینه‌ی تیره پیش‌فرض است — شبِ لاجورد، و نور که از دلِ آن می‌زند.
  final ThemeMode themeMode;
  final double textScale;
  final bool reducedMotion;
  final bool dyslexic;

  /// ضرب‌های سنتور.
  final bool sound;

  /// null = هنوز از دیسک نخوانده‌ایم.
  final bool? onboarded;

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? textScale,
    bool? reducedMotion,
    bool? dyslexic,
    bool? sound,
    bool? onboarded,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        textScale: textScale ?? this.textScale,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        dyslexic: dyslexic ?? this.dyslexic,
        sound: sound ?? this.sound,
        onboarded: onboarded ?? this.onboarded,
      );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._repository) : super(const AppSettings()) {
    _load();
  }

  final ProgressRepository? _repository;

  static const _kTheme = 'themeMode';
  static const _kScale = 'textScale';
  static const _kMotion = 'reducedMotion';
  static const _kDyslexic = 'dyslexic';
  static const _kSound = 'sound';
  static const _kOnboarded = 'onboarded';

  Future<void> _load() async {
    final repo = _repository;
    if (repo == null) {
      // بی‌مخزن (آزمون‌ها): چیزی برای خواندن نیست؛ خوشامد را هم نخواه.
      state = state.copyWith(onboarded: true);
      return;
    }
    final values = <String, String?>{
      for (final key in const [
        _kTheme,
        _kScale,
        _kMotion,
        _kDyslexic,
        _kSound,
        _kOnboarded,
      ])
        key: await repo.setting(key),
    };
    if (!mounted) return;
    state = AppSettings(
      themeMode: switch (values[_kTheme]) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      },
      textScale: double.tryParse(values[_kScale] ?? '') ?? 1.0,
      reducedMotion: values[_kMotion] == '1',
      dyslexic: values[_kDyslexic] == '1',
      sound: values[_kSound] != '0',
      onboarded: values[_kOnboarded] == '1',
    );
  }

  Future<void> _put(String key, String value) async =>
      _repository?.putSetting(key, value);

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _put(
      _kTheme,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
        ThemeMode.dark => 'dark',
      },
    );
  }

  void setTextScale(double scale) {
    state = state.copyWith(textScale: scale);
    _put(_kScale, '$scale');
  }

  void setReducedMotion({required bool on}) {
    state = state.copyWith(reducedMotion: on);
    _put(_kMotion, on ? '1' : '0');
  }

  void setDyslexic({required bool on}) {
    state = state.copyWith(dyslexic: on);
    _put(_kDyslexic, on ? '1' : '0');
  }

  void setSound({required bool on}) {
    state = state.copyWith(sound: on);
    _put(_kSound, on ? '1' : '0');
  }

  void markOnboarded() {
    state = state.copyWith(onboarded: true);
    _put(_kOnboarded, '1');
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(ref.watch(progressRepositoryProvider)),
);

/// صدا — روشن/خاموشش دستِ کاربر است.
final soundProvider = Provider<SoundService>(
  (ref) => SoundService(
    enabled: ref.watch(settingsProvider.select((s) => s.sound)),
  ),
);
