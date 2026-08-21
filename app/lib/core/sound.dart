// صدای سره — ضرب‌های سنتور.
//
// قاعده‌ها (ETHICS و برداشتِ کاربرمحور از صدا):
//
//   • صدا چاشنی است، نه شرط: هر رویداد بی‌صدا هم کامل فهمیده می‌شود، پس
//     خاموش‌کردنش چیزی از اپ کم نمی‌کند و شکستِ پخش هم بی‌صدا بلعیده
//     می‌شود — تمرین هرگز پشتِ پخشِ صدا گیر نمی‌کند.
//   • صدای پاسخِ نادرست از پاداش نرم‌تر و آرام‌تر است — خبر است، نه تنبیه.
//   • هیچ صدای پس‌زمینه‌ای در کار نیست؛ تنها ضربِ کوتاه بر رویداد. صدای
//     مدام، به‌ویژه در اپِ آموزشی، زود به آزار می‌رسد.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// جلوه‌های موجود — نام‌ها با پرونده‌های `assets/sounds/` یکی است.
enum Sfx {
  /// پاسخِ درست: دو ضربِ روشنِ بالارونده.
  dorost('dorost.wav'),

  /// پاسخِ نادرست: ضربِ بمِ خفه — نرم‌تر و آرام‌تر از پاداش.
  nadorost('nadorost.wav'),

  /// پایانِ منزل: پویه‌ی پنج‌ضربی در مایه‌ی شور.
  manzel('manzel.wav'),

  /// منزلِ بی‌لغزش: همان پویه با تاجِ یک اکتاو بالاتر.
  gohar('gohar.wav');

  const Sfx(this.file);

  final String file;
}

class SoundService {
  SoundService({this.enabled = true});

  /// از تنظیماتِ کاربر می‌آید؛ خاموش یعنی [play] هیچ کاری نمی‌کند.
  bool enabled;

  Future<void> play(Sfx sfx) async {
    if (!enabled) return;
    try {
      final player = AudioPlayer();
      // پخش که تمام شد، خودش جمع می‌شود؛ ضرب‌ها کوتاه‌تر از آن‌اند که
      // نگه‌داشتنِ استخرِ پخش‌کننده بیرزد.
      player.onPlayerComplete.listen((_) => player.dispose());
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.play(AssetSource('sounds/${sfx.file}'));
    } catch (error) {
      // بی‌صدا: در آزمون‌ها افزونه‌ی صدا نیست و روی دستگاه هم اگر پخش
      // شکست، تمرین نباید بایستد.
      debugPrint('پخشِ صدا نشد: $error');
    }
  }
}
