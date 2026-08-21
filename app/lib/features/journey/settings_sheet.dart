// برگه‌ی تنظیمات — از سرصفحه‌ی هفت‌خان باز می‌شود.
//
// هر گزینه همان لحظه کار می‌کند و همان لحظه روی دیسک می‌نشیند؛ دکمه‌ی
// «ذخیره» ندارد چون چیزی برای از دست دادن نیست.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../design/tokens.g.dart';

Future<void> showSettingsSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SarehRadius.card),
        ),
      ),
      builder: (context) => const _SettingsSheet(),
    );

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SarehSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SarehSpace.lg),
              child: Text(
                'تنظیمات',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: SarehSpace.sm),
            SwitchListTile(
              title: const Text('صدا'),
              subtitle: const Text('ضرب‌های سنتور برای پاسخ و پایانِ منزل'),
              value: settings.sound,
              onChanged: (on) => notifier.setSound(on: on),
            ),
            SwitchListTile(
              title: const Text('کاهشِ حرکت'),
              subtitle: const Text('انیمیشن‌ها خاموش؛ هیچ کارکردی از دست نمی‌رود'),
              value: settings.reducedMotion,
              onChanged: (on) => notifier.setReducedMotion(on: on),
            ),
            SwitchListTile(
              title: const Text('قلمِ خوانا'),
              subtitle: const Text('برای دیس‌لکسی — حروفِ بازتر'),
              value: settings.dyslexic,
              onChanged: (on) => notifier.setDyslexic(on: on),
            ),
            SwitchListTile(
              title: const Text('پوسته‌ی روشن'),
              subtitle: const Text('پیش‌فرض، شبِ لاجورد است'),
              value: settings.themeMode == ThemeMode.light,
              onChanged: (on) =>
                  notifier.setThemeMode(on ? ThemeMode.light : ThemeMode.dark),
            ),
          ],
        ),
      ),
    );
  }
}
