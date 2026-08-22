// نشان‌های سره — سیمرغ، شیر و خورشید، گلِ تختِ جمشید، هفت نگهبان.
//
// ── چرا سیلوئتِ پُر و نه خطِ نازک ──
//
// نسخه‌ی نخست همه را با `PaintingStyle.stroke` می‌کشید و نتیجه نامفهوم
// بود: خطِ نازک در ۵۶ پیکسل به خاکستریِ بی‌شکل می‌رسد و مغز هیچ چیزی
// در آن بازنمی‌شناسد. آزمونِ یک نشانِ آیکونیک این است که اگر سراسر
// سیاهش کنی باز هم بتوانی نامش را بگویی — و این تنها از سیلوئتِ پُر
// برمی‌آید. پس هر نقشِ اینجا یک مسیرِ پُر است، و جزئیاتِ درونی
// (چشم، دهان، چشمِ پر) سوراخ‌اند نه خط: با `PathOperation.difference`
// بریده می‌شوند، پس هر زمینه‌ای از پشتشان دیده می‌شود.
//
// همه در فضای ۱۰۰×۱۰۰ طراحی شده‌اند و هنگامِ کشیدن مقیاس می‌خورند، پس
// در هر اندازه‌ای تیزند و APK را سنگین نمی‌کنند.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

// ─────────────────────── ابزارِ هندسه ───────────────────────

const double _unit = 100;

void _disc(Path p, double cx, double cy, double r) =>
    p.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

void _poly(Path p, List<Offset> points) {
  if (points.isEmpty) return;
  p.moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    p.lineTo(point.dx, point.dy);
  }
  p.close();
}

/// کمانِ درجه‌دوم به‌صورتِ زنجیره‌ی نقطه — ستون‌فقراتِ [_ribbon].
List<Offset> _curve(Offset a, Offset b, Offset c, {int steps = 28}) {
  return [
    for (var i = 0; i < steps; i++)
      () {
        final t = i / (steps - 1);
        final u = 1 - t;
        return Offset(
          u * u * a.dx + 2 * u * t * b.dx + t * t * c.dx,
          u * u * a.dy + 2 * u * t * b.dy + t * t * c.dy,
        );
      }(),
  ];
}

/// نوارِ پهنِ باریک‌شونده روی یک ستون‌فقرات — تیغه، شاخ، گردن.
void _ribbon(Path p, List<Offset> spine, double from, double to) {
  if (spine.length < 2) return;
  final left = <Offset>[];
  final right = <Offset>[];
  for (var i = 0; i < spine.length; i++) {
    final t = i / (spine.length - 1);
    final width = from + (to - from) * t;
    final ahead = spine[math.min(i + 1, spine.length - 1)];
    final behind = spine[math.max(i - 1, 0)];
    final delta = ahead - behind;
    final length = delta.distance == 0 ? 1.0 : delta.distance;
    final normal = Offset(-delta.dy / length, delta.dx / length);
    left.add(spine[i] + normal * width);
    right.add(spine[i] - normal * width);
  }
  _poly(p, [...left, ...right.reversed]);
}

/// تیغه‌ی باریک‌شونده از یک نقطه با یک زاویه — پرتوِ خورشید، شاخ، پر.
Offset _taper(
  Path p,
  Offset origin,
  double angle,
  double length,
  double half, {
  double tip = 0,
}) {
  final along = Offset(math.cos(angle), math.sin(angle));
  final across = Offset(-along.dy, along.dx);
  final end = origin + along * length;
  _poly(p, [
    origin + across * half,
    end + across * (half * 0.2),
    end - across * (half * 0.2),
    origin - across * half,
  ]);
  if (tip > 0) _disc(p, end.dx, end.dy, tip);
  return end;
}

/// بادامِ دوسر‌تیز — گلبرگِ گل و پرِ دمِ سیمرغ هر دو از این‌اند.
void _petal(Path p, Offset centre, double angle, double long, double wide) {
  const steps = 24;
  final outline = <Offset>[];
  for (var side = 0; side < 2; side++) {
    for (var k = 0; k <= steps; k++) {
      final t = side == 0 ? k / steps : 1 - k / steps;
      final swell = math.pow(math.sin(math.pi * t), 0.75).toDouble();
      outline.add(
        Offset(-long + 2 * long * t, (side == 0 ? wide : -wide) * swell),
      );
    }
  }
  final ca = math.cos(angle);
  final sa = math.sin(angle);
  _poly(p, [
    for (final o in outline)
      centre + Offset(o.dx * ca - o.dy * sa, o.dx * sa + o.dy * ca),
  ]);
}

/// نقش، به‌صورتِ لایه‌های پیاپیِ «بیفزا» و «ببُر».
///
/// **ترتیب مهم است.** ساده‌ترین پیاده‌سازی این بود که همه‌ی تنه‌ها در یک
/// مسیر و همه‌ی سوراخ‌ها در مسیری دیگر جمع شوند و یک بار از هم کم شوند —
/// ولی آنگاه هر تنه‌ای که *پس از* یک سوراخ کشیده شده باشد ناپدید می‌شود.
/// دو نقش دقیقاً همین‌اند: مرکزِ گلِ آپادانا (قرص، سوراخ، و باز قرصِ
/// کوچک‌تر) و نیش‌های دیو سپید (که روی سوراخِ دهان می‌نشینند).
///
/// پس لایه‌ها به ترتیب نگه داشته می‌شوند و همان‌گونه تا می‌خورند. لایه‌ی
/// تازه تنها وقتی باز می‌شود که گونه‌ی کار عوض شود، پس هر نقش دو تا چهار
/// `Path.combine` می‌خواهد، نه ده‌ها تا.
class _Mark {
  final List<(Path, bool)> _layers = [];

  Path _layer({required bool cut}) {
    if (_layers.isEmpty || _layers.last.$2 != cut) {
      _layers.add((Path(), cut));
    }
    return _layers.last.$1;
  }

  /// لایه‌ای که به نقش افزوده می‌شود.
  Path get solid => _layer(cut: false);

  /// لایه‌ای که از نقش بریده می‌شود — چشم، دهان، چشمِ پر.
  Path get holes => _layer(cut: true);

  Path build() {
    var out = Path();
    for (final (path, cut) in _layers) {
      out = Path.combine(
        cut ? PathOperation.difference : PathOperation.union,
        out,
        path,
      );
    }
    return _fit(out);
  }

  /// نقش را در کادرِ ۱۰۰×۱۰۰ می‌نشاند: هم‌مقیاس، وسط‌چین.
  ///
  /// بی این، مختصاتِ دستی از کادر بیرون می‌زدند و کسی نمی‌فهمید: دمِ
  /// سیمرغ تا ۱۱۸ می‌رفت و بال‌های قرصِ فَرّ از ۳۶- تا ۱۳۶ — یعنی روی
  /// همسایه‌ها می‌افتادند یا بریده می‌شدند. حالا هر نقش دقیقاً کادرش را
  /// پر می‌کند، پس اندازه‌شان کنارِ هم هم یکدست است.
  static Path _fit(Path path) {
    final box = path.getBounds();
    if (box.isEmpty) return path;
    final scale = _unit / math.max(box.width, box.height);
    final dx = (_unit - box.width * scale) / 2 - box.left * scale;
    final dy = (_unit - box.height * scale) / 2 - box.top * scale;
    return path.transform(
      Float64List.fromList([
        scale, 0, 0, 0, //
        0, scale, 0, 0, //
        0, 0, 1, 0, //
        dx, dy, 0, 1, //
      ]),
    );
  }
}

/// کشنده‌ی یک نقش در فضای ۱۰۰×۱۰۰.
typedef _Tracer = void Function(_Mark mark);

/// همه‌ی نشان‌ها، به نام. هندسه به رنگ و اندازه بستگی ندارد، پس یک
/// جدولِ ساده بس است — و همین جدول است که آزمون رویش می‌گردد.
final Map<String, _Tracer> _tracers = {
  'simorgh': _traceSimorgh,
  'shirokhorshid': _traceShirOKhorshid,
  'rosette': _traceRosette,
  'farr': _traceFarr,
  'atash': _traceAtash,
  'gohar': _traceGohar,
  for (var khan = 1; khan <= 7; khan++)
    'guardian-$khan': (mark) => _traceGuardian(mark, khan),
};

/// نقاشِ یگانه‌ی همه‌ی نشان‌ها.
///
/// مسیر یک بار ساخته و به نام کش می‌شود؛ وگرنه `Path.combine` در هر
/// فریم دوباره اجرا می‌شد.
class _EmblemPainter extends CustomPainter {
  const _EmblemPainter(this.name, this.colour);

  static final Map<String, Path> _cache = {};

  final String name;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _cache.putIfAbsent(name, () => emblemPath(name));
    canvas
      ..save()
      ..scale(size.shortestSide / _unit)
      ..drawPath(path, Paint()..color = colour)
      ..restore();
  }

  @override
  bool shouldRepaint(_EmblemPainter old) =>
      old.name != name || old.colour != colour;
}

/// مسیرِ نهاییِ یک نشان در فضای ۱۰۰×۱۰۰.
///
/// درزِ آزمون هم هست: `toImage` در بایندینگِ آزمون قفل می‌کند، پس تنها
/// راهِ سنجیدنِ هندسه همین است. آزمون با آن وارسی می‌کند که هر نقش کادرش
/// را پر می‌کند و سوراخ‌هایش واقعاً بریده شده‌اند.
@visibleForTesting
Path emblemPath(String name) {
  final tracer = _tracers[name];
  if (tracer == null) throw ArgumentError('نشانِ ناشناخته: $name');
  final mark = _Mark();
  tracer(mark);
  return mark.build();
}

/// نامِ همه‌ی نشان‌ها — تا آزمون بتواند بر همه بگردد.
@visibleForTesting
const List<String> emblemNames = [
  'simorgh',
  'shirokhorshid',
  'rosette',
  'farr',
  'atash',
  'gohar',
  'guardian-1',
  'guardian-2',
  'guardian-3',
  'guardian-4',
  'guardian-5',
  'guardian-6',
  'guardian-7',
];

// ─────────────────────── سیمرغ ───────────────────────

/// سیمرغ — همراهِ کاربر در سراسرِ راه.
///
/// نیم‌رخ، نه رو‌به‌رو: پرنده‌ی نیم‌رخ بی‌درنگ «پرنده» خوانده می‌شود، چون
/// منقار و تاج در نیم‌رخ دیده می‌شوند. دمِ طاووسیِ **هفت‌پر** — هفت خان —
/// بزرگ‌ترین بخشِ نقش است، چون همان است که «سیمرغ» می‌گوید نه «عقاب»؛
/// چشمِ هر پر از دلش بریده شده، مثلِ پرِ طاووس.
///
/// در شاهنامه سیمرغ راهنماست نه داور: زال را می‌پرورد و رستم را در
/// سخت‌ترین جا راه می‌نماید. پس سرش همیشه برافراشته است.
class SimorghEmblem extends StatelessWidget {
  const SimorghEmblem({super.key, required this.size, required this.colour});

  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _EmblemPainter('simorgh', colour),
      );
}

void _traceSimorgh(_Mark m) {
  // دمِ طاووسی — هفت پر، هرکدام با چشمِ بریده.
  const root = Offset(56, 58);
  for (var i = 0; i < 7; i++) {
    final u = i / 6;
    final angle = (12 + 76 * u) * math.pi / 180;
    final length = 25 + 7 * math.sin(math.pi * u);
    final along = Offset(math.cos(angle), math.sin(angle));
    _petal(m.solid, root + along * (length + 5), angle, length, 3.5);
    final eye = root + along * (length * 1.7 + 2);
    _disc(m.holes, eye.dx, eye.dy, 3);
  }

  // بدنه.
  _poly(m.solid, const [
    Offset(34, 40),
    Offset(48, 36),
    Offset(60, 44),
    Offset(62, 58),
    Offset(52, 66),
    Offset(38, 62),
    Offset(31, 50),
  ]);

  // بالِ برافراشته، با کنگره‌ی پرها در لبه‌ی پسین.
  _poly(m.solid, const [
    Offset(44, 44),
    Offset(56, 30),
    Offset(70, 20),
    Offset(84, 16),
    Offset(76, 26),
    Offset(82, 27),
    Offset(70, 36),
    Offset(74, 39),
    Offset(60, 44),
    Offset(62, 49),
    Offset(49, 52),
  ]);

  // گردن، سر، تاجِ سه‌پر، منقارِ قلاب‌دار.
  _poly(m.solid, const [
    Offset(31, 46),
    Offset(26, 34),
    Offset(34, 28),
    Offset(40, 40),
  ]);
  _disc(m.solid, 30, 29, 8);
  for (final (angle, length) in const [
    (-58.0, 15.0),
    (-32.0, 13.0),
    (-8.0, 11.0),
  ]) {
    _taper(m.solid, const Offset(34, 24), angle * math.pi / 180, length, 2.3);
  }
  _poly(m.solid, const [Offset(24, 26), Offset(24, 33), Offset(12, 31)]);
  _poly(m.holes, const [Offset(19, 29), Offset(24, 31), Offset(19, 33)]);
  _disc(m.holes, 29, 27, 1.9);

  // دو پا.
  for (final x in const [42.0, 50.0]) {
    _taper(m.solid, Offset(x, 62), 78 * math.pi / 180, 12, 1.5);
    _taper(m.solid, Offset(x + 1, 73), 20 * math.pi / 180, 6, 1.3);
  }
}

// ─────────────────────── شیر و خورشید ───────────────────────

/// شیر و خورشید — نشانِ خودِ سره.
///
/// ریشه‌اش اخترشناختی است و پیش از اسلام: خورشید در خانه‌ی اسد (شیر).
/// شیر شهریاری است و خورشید مهر — هر دو از ایرانِ کهن.
///
/// دو چیز آگاهانه اینجا **نیست**: تیغه‌ی دوشاخه‌ی ذوالفقار، که پیوندِ
/// دوره‌ی صفوی و قاجار با معنایی دینی است و با «بدور از اسلام»ِ این
/// پروژه نمی‌خوانَد — به‌جایش شمشیرِ خمیده‌ی ایرانی؛ و تاجِ قاجاری، که
/// نشانِ یک دودمان است نه نشانِ یک زبان.
///
/// چیدمان: تیغه میانِ سر و خورشید می‌ایستد، وگرنه با یالْ شاخ به نظر
/// می‌آید و با خورشیدْ پرتو.
class ShirOKhorshid extends StatelessWidget {
  const ShirOKhorshid({super.key, required this.size, required this.colour});

  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _EmblemPainter('shirokhorshid', colour),
      );
}

void _traceShirOKhorshid(_Mark m) {
  // خورشید بالای کفل.
  const sun = Offset(76, 25);
  const radius = 12.0;
  for (var i = 0; i < 16; i++) {
    _taper(m.solid, sun, math.pi * 2 * i / 16, radius + 10, 2.4);
  }
  _disc(m.solid, sun.dx, sun.dy, radius);
  _disc(m.holes, sun.dx, sun.dy, radius - 4);

  // شمشیرِ خمیده در پنجه‌ی برافراشته.
  _ribbon(
    m.solid,
    _curve(const Offset(45, 50), const Offset(42, 30), const Offset(51, 13)),
    4.6,
    1,
  );
  _taper(m.solid, const Offset(40, 52), -8 * math.pi / 180, 13, 2);
  _ribbon(
    m.solid,
    _curve(const Offset(49, 66), const Offset(44, 58), const Offset(45, 51)),
    3.6,
    3.2,
  );
  _disc(m.solid, 45, 50, 4.4);

  // تنه، رو به چپ، با چهار پای استوار.
  _poly(m.solid, const [
    Offset(34, 60),
    Offset(48, 55),
    Offset(62, 56),
    Offset(72, 62),
    Offset(74, 74),
    Offset(69, 74),
    Offset(68, 88),
    Offset(63, 88),
    Offset(62, 74),
    Offset(54, 75),
    Offset(53, 88),
    Offset(49, 88),
    Offset(48, 75),
    Offset(42, 75),
    Offset(41, 88),
    Offset(37, 88),
    Offset(36, 74),
    Offset(32, 72),
  ]);
  _taper(m.solid, const Offset(73, 64), -62 * math.pi / 180, 16, 1.8);
  _disc(m.solid, 81, 51, 3.2);

  // سر با یالِ لُپ‌دار، پایین‌تر از تیغه.
  const head = Offset(27, 61);
  for (var i = 0; i < 9; i++) {
    final a = math.pi * 2 * i / 9 + 0.35;
    _disc(
      m.solid,
      head.dx + math.cos(a) * 9.5,
      head.dy + math.sin(a) * 9.5,
      5.2,
    );
  }
  _disc(m.solid, head.dx, head.dy, 10.5);
  _poly(m.solid, [
    head + const Offset(-9, -4),
    head + const Offset(-19, 1),
    head + const Offset(-9, 7),
  ]);
  _disc(m.holes, head.dx - 4, head.dy - 3, 1.8);
}

// ─────────────────────── گلِ تختِ جمشید ───────────────────────

/// گلِ دوازده‌پر — همان که بند‌بند بر پلکانِ آپادانا تکرار می‌شود.
///
/// دوازده گلبرگ، دوازده ماهِ سال. بر نقشِ برجسته‌ها نمایندگانِ ملت‌ها
/// همین گل را به دست دارند: نشانِ آشتی و پاکی، نه نشانِ چیرگی. کوچک‌ترین
/// نقشِ هخامنشی است و همان است که به کارِ آذینِ ریز می‌آید.
class PersepolisRosette extends StatelessWidget {
  const PersepolisRosette({
    super.key,
    required this.size,
    required this.colour,
  });

  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _EmblemPainter('rosette', colour),
      );
}

void _traceRosette(_Mark m) {
  const c = Offset(50, 50);
  for (var i = 0; i < 12; i++) {
    final a = math.pi * 2 * i / 12 - math.pi / 2;
    _petal(m.solid, c + Offset(math.cos(a), math.sin(a)) * 26, a, 20, 7);
  }
  _disc(m.solid, c.dx, c.dy, 12);
  _disc(m.holes, c.dx, c.dy, 8);
  _disc(m.solid, c.dx, c.dy, 4);
}

/// نوارِ گل — همان تکرارِ افقی که بر پلکان می‌دود، برای جداکردنِ بخش‌ها.
class RosetteBand extends StatelessWidget {
  const RosetteBand({
    super.key,
    required this.colour,
    this.height = 14,
    this.count = 9,
  });

  final Color colour;
  final double height;
  final int count;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < count; i++)
              PersepolisRosette(size: height, colour: colour),
          ],
        ),
      );
}

// ─────────────────────── آیکن‌های شمارگان ───────────────────────

/// نشانِ فَرّ — قرصِ بالدار.
class FarrIcon extends StatelessWidget {
  const FarrIcon({super.key, required this.size, required this.colour});

  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _EmblemPainter('farr', colour),
      );
}

void _traceFarr(_Mark m) {
  // بال‌ها: سه بندِ پله‌ای در هر سو.
  for (final side in const [-1, 1]) {
    for (var i = 0; i < 3; i++) {
      final y = 26.0 + i * 12;
      _poly(m.solid, [
        Offset(50 + side * 14, y - 4.5),
        Offset(50 + side * (48 - i * 8), y - 4.5),
        Offset(50 + side * (48 - i * 8), y + 4.5),
        Offset(50 + side * 14, y + 4.5),
      ]);
    }
    // شرابه‌ی پیچانِ کنارِ دم.
    _ribbon(
      m.solid,
      _curve(
        Offset(50 + side * 12, 62),
        Offset(50 + side * 30, 68),
        Offset(50 + side * 24, 84),
      ),
      3.5,
      2,
    );
  }
  // قرصِ میانی.
  _disc(m.solid, 50, 34, 17);
  _disc(m.holes, 50, 34, 9);
  // دمِ پله‌ای زیرِ قرص — بی آن، نقش سه‌برابرِ بلندایش پهن می‌شد و در
  // ردیفِ شمارگان، که با بلندا اندازه می‌گیرد، ریز می‌نمود.
  _poly(m.solid, const [
    Offset(38, 52),
    Offset(62, 52),
    Offset(60, 70),
    Offset(56, 70),
    Offset(54, 88),
    Offset(46, 88),
    Offset(44, 70),
    Offset(40, 70),
  ]);
}

/// نشانِ زنجیره — آتشِ جاویدان بر آتشدانِ پلکانی.
class AtashIcon extends StatelessWidget {
  const AtashIcon({super.key, required this.size, required this.colour});

  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _EmblemPainter('atash', colour),
      );
}

void _traceAtash(_Mark m) {
  _poly(m.solid, const [
    Offset(50, 6),
    Offset(70, 34),
    Offset(62, 44),
    Offset(66, 58),
    Offset(50, 68),
    Offset(34, 58),
    Offset(38, 44),
    Offset(30, 34),
  ]);
  _poly(m.holes, const [
    Offset(50, 30),
    Offset(58, 46),
    Offset(50, 58),
    Offset(42, 46),
  ]);
  _poly(m.solid, const [
    Offset(22, 96),
    Offset(22, 86),
    Offset(34, 86),
    Offset(34, 76),
    Offset(66, 76),
    Offset(66, 86),
    Offset(78, 86),
    Offset(78, 96),
  ]);
}

/// نشانِ گوهر — لوزیِ تراش‌خورده.
class GoharIcon extends StatelessWidget {
  const GoharIcon({super.key, required this.size, required this.colour});

  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _EmblemPainter('gohar', colour),
      );
}

void _traceGohar(_Mark m) {
  _poly(m.solid, const [
    Offset(14, 38),
    Offset(32, 12),
    Offset(68, 12),
    Offset(86, 38),
    Offset(50, 90),
  ]);
  for (final line in const [
    [Offset(14, 38), Offset(86, 38)],
    [Offset(32, 12), Offset(50, 90)],
    [Offset(68, 12), Offset(50, 90)],
  ]) {
    _ribbon(m.holes, line, 1.8, 1.8);
  }
}

// ─────────────────────── نگهبانانِ هفت خان ───────────────────────

/// نشانِ نگهبانِ یک خان — سیلوئتِ پُر، به رنگِ همان خان.
///
/// هر نقش از خودِ داستانِ هفت‌خان آمده، نه از هندسه‌ی دلبخواه:
///
///   ۱ شیر         کله‌ی یال‌دار — نخستین آزمون، که رخش آن را کشت
///   ۲ دیو تشنگی   خورشیدِ سوزان و یک قطره — بیابانِ بی‌آب
///   ۳ اژدها       سرِ شاخ‌دار با آرواره‌ی باز
///   ۴ جادو        نیم‌رخِ زیبا با شاخی پنهان در گیسو — آنچه هست، نه آنچه می‌نماید
///   ۵ اولاد       گره — راهنمایی که نخست اسیر شد
///   ۶ ارژنگ       گرزِ گاوسر، سلاحِ رستم در آن نبرد
///   ۷ دیو سپید    کله‌ی سترگِ شاخ‌دار با نیش — واپسین و بزرگ‌ترین
///
/// شماره‌ی خان ۱ تا ۷ است؛ بیرون از بازه، نگهبانِ نخست کشیده می‌شود.
class GuardianEmblem extends StatelessWidget {
  const GuardianEmblem({
    super.key,
    required this.khan,
    required this.size,
    required this.colour,
  });

  final int khan;
  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        // خانِ بیرون از بازه به نگهبانِ نخست برمی‌گردد.
        painter: _EmblemPainter(
          'guardian-${khan >= 1 && khan <= 7 ? khan : 1}',
          colour,
        ),
      );
}

void _traceGuardian(_Mark m, int khan) {
  switch (khan) {
    case 1:
      _lionHead(m);
    case 2:
      _thirst(m);
    case 3:
      _dragon(m);
    case 4:
      _enchantress(m);
    case 5:
      _knot(m);
    case 6:
      _gorz(m);
    default:
      _whiteDiv(m);
  }
}

void _lionHead(_Mark m) {
  for (var i = 0; i < 12; i++) {
    final a = math.pi * 2 * i / 12 + 0.26;
    _disc(m.solid, 50 + math.cos(a) * 26, 52 + math.sin(a) * 26, 12);
  }
  _disc(m.solid, 50, 52, 28);
  for (final side in const [-1, 1]) {
    _disc(m.solid, 50 + side * 22, 30, 8);
    _disc(m.holes, 50 + side * 22, 30, 3.4);
    _poly(m.holes, [
      Offset(50 + side * 6, 46),
      Offset(50 + side * 17, 43),
      Offset(50 + side * 17, 50),
      Offset(50 + side * 6, 51),
    ]);
  }
  _poly(m.holes, const [Offset(44, 60), Offset(56, 60), Offset(50, 67)]);
  _poly(m.holes, const [
    Offset(50, 67),
    Offset(52, 74),
    Offset(60, 76),
    Offset(50, 79),
    Offset(40, 76),
    Offset(48, 74),
  ]);
}

void _thirst(_Mark m) {
  for (var i = 0; i < 14; i++) {
    _taper(m.solid, const Offset(50, 34), math.pi * 2 * i / 14, 32, 3.2);
  }
  _disc(m.solid, 50, 34, 19);
  _disc(m.holes, 50, 34, 13);
  _poly(m.solid, const [
    Offset(50, 58),
    Offset(64, 78),
    Offset(50, 94),
    Offset(36, 78),
  ]);
  _disc(m.holes, 50, 80, 5.6);
}

void _dragon(_Mark m) {
  _ribbon(
    m.solid,
    _curve(const Offset(18, 88), const Offset(14, 56), const Offset(40, 48)),
    8,
    7,
  );
  _poly(m.solid, const [
    Offset(34, 34),
    Offset(62, 30),
    Offset(76, 40),
    Offset(86, 38),
    Offset(78, 48),
    Offset(86, 54),
    Offset(66, 56),
    Offset(44, 58),
  ]);
  _poly(m.holes, const [Offset(66, 44), Offset(80, 42), Offset(74, 47)]);
  _taper(m.solid, const Offset(44, 34), -118 * math.pi / 180, 22, 3.6);
  _taper(m.solid, const Offset(56, 32), -96 * math.pi / 180, 15, 3);
  _disc(m.holes, 60, 40, 3.4);
  for (final x in const [52.0, 62.0, 72.0]) {
    _poly(m.solid, [Offset(x, 52), Offset(x + 5, 52), Offset(x + 2, 59)]);
  }
}

void _enchantress(_Mark m) {
  // گیسو، باریک‌تر از چهره — وگرنه رداپوش می‌نماید نه زن.
  _poly(m.solid, const [
    Offset(56, 22),
    Offset(74, 34),
    Offset(78, 58),
    Offset(72, 78),
    Offset(78, 92),
    Offset(56, 92),
    Offset(58, 70),
    Offset(54, 54),
  ]);
  _poly(m.solid, const [
    Offset(56, 22),
    Offset(66, 34),
    Offset(64, 52),
    Offset(56, 62),
    Offset(58, 72),
    Offset(44, 72),
    Offset(40, 60),
    Offset(34, 52),
    Offset(40, 48),
    Offset(36, 42),
    Offset(42, 26),
  ]);
  _poly(m.solid, const [Offset(34, 52), Offset(26, 55), Offset(36, 60)]);
  _disc(m.holes, 45, 46, 3.2);
  _poly(m.holes, const [Offset(37, 63), Offset(49, 65), Offset(37, 68)]);
  _poly(m.solid, const [
    Offset(46, 72),
    Offset(60, 72),
    Offset(62, 88),
    Offset(44, 88),
  ]);
  _taper(m.solid, const Offset(62, 24), -58 * math.pi / 180, 22, 3.6);
}

void _knot(_Mark m) {
  // دو حلقه‌ی عمود بر هم — گره، نه زنجیر. پیش‌تر هر دو هم‌راستا بودند
  // و نقش پهنِ کوتاه درمی‌آمد؛ کنارِ شش نگهبانِ دیگر ریز می‌نمود.
  for (final upright in const [false, true]) {
    final spine = <Offset>[];
    for (var k = 0; k < 60; k++) {
      final th = math.pi * 2 * k / 59;
      final r = 30 + 9 * math.cos(2 * th);
      final along = math.cos(th) * r;
      final across = math.sin(th) * r * 0.62;
      spine.add(
        upright
            ? Offset(50 + across, 50 + along)
            : Offset(50 + along, 50 + across),
      );
    }
    _ribbon(m.solid, spine, 5.5, 5.5);
  }
  _disc(m.solid, 50, 50, 9);
}

void _gorz(_Mark m) {
  _ribbon(m.solid, const [Offset(50, 40), Offset(50, 92)], 4.6, 3.4);
  _disc(m.solid, 50, 88, 6);
  _disc(m.solid, 50, 32, 17);
  for (final side in const [-1, 1]) {
    _ribbon(
      m.solid,
      _curve(
        Offset(50 + side * 14, 26),
        Offset(50 + side * 30, 20),
        Offset(50 + side * 26, 4),
      ),
      4.4,
      1.4,
    );
    _disc(m.holes, 50 + side * 7, 30, 3);
  }
  _poly(m.solid, const [
    Offset(42, 34),
    Offset(58, 34),
    Offset(54, 46),
    Offset(46, 46),
  ]);
  _poly(m.holes, const [
    Offset(46, 42),
    Offset(54, 42),
    Offset(52, 46),
    Offset(48, 46),
  ]);
}

void _whiteDiv(_Mark m) {
  for (final side in const [-1, 1]) {
    _ribbon(
      m.solid,
      _curve(
        Offset(50 + side * 24, 40),
        Offset(50 + side * 44, 26),
        Offset(50 + side * 34, 4),
      ),
      6,
      1.6,
    );
    _poly(m.holes, [
      Offset(50 + side * 8, 44),
      Offset(50 + side * 24, 40),
      Offset(50 + side * 22, 52),
      Offset(50 + side * 8, 52),
    ]);
  }
  _poly(m.solid, const [
    Offset(24, 42),
    Offset(36, 28),
    Offset(64, 28),
    Offset(76, 42),
    Offset(72, 68),
    Offset(58, 86),
    Offset(42, 86),
    Offset(28, 68),
  ]);
  _poly(m.holes, const [Offset(44, 58), Offset(56, 58), Offset(50, 66)]);
  _poly(m.holes, const [
    Offset(34, 70),
    Offset(66, 70),
    Offset(60, 80),
    Offset(40, 80),
  ]);
  for (final x in const [38.0, 46.0, 54.0, 60.0]) {
    _poly(m.solid, [Offset(x, 70), Offset(x + 5, 70), Offset(x + 2, 78)]);
  }
}
