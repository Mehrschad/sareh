// تبدیلِ دادهٔ مسیرِ SVG به `Path`.
//
// «نورِ واژه» باید دقیقاً مسیرِ قلمِ نستعلیق را بپیماید، پس به خطِ واقعیِ واژه
// نیاز دارد نه به یک مستطیل. مسیرها یک بار از قلم گلزار بیرون کشیده می‌شوند و
// به‌صورت رشته‌ی `d` در `assets/word_paths/` می‌نشینند؛ این تجزیه‌گر آنها را به
// `Path` برمی‌گرداند. برای واژه‌های پرتکرار، خروجی کش می‌شود (بخش ۳٫۵).
//
// زیرمجموعه‌ی پشتیبانی‌شده: M m L l H h V v C c S s Q q T t A a Z z — یعنی هرچه
// یک خروجیِ معمولیِ قلم تولید می‌کند.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

class SvgPathParseException implements Exception {
  SvgPathParseException(this.message);
  final String message;
  @override
  String toString() => 'SvgPathParseException: $message';
}

/// رشته‌ی `d` را به `Path` تبدیل می‌کند.
Path parseSvgPath(String d) {
  final parser = _Parser(d);
  return parser.run();
}

class _Parser {
  _Parser(this.source);

  final String source;
  final Path path = Path();
  int index = 0;

  Offset current = Offset.zero;
  Offset start = Offset.zero;

  /// نقطه‌ی مهارِ بازتابی برای S/T.
  Offset? lastCubicControl;
  Offset? lastQuadraticControl;

  Path run() {
    var command = '';
    while (true) {
      _skipSeparators();
      if (index >= source.length) break;

      final char = source[index];
      if (_isCommand(char)) {
        command = char;
        index++;
      } else if (command.isEmpty) {
        throw SvgPathParseException('مسیر با فرمان آغاز نمی‌شود: $source');
      } else if (command == 'M') {
        // Repeated coordinate pairs after a moveto are implicit linetos.
        command = 'L';
      } else if (command == 'm') {
        command = 'l';
      }
      _run(command);
    }
    return path;
  }

  void _run(String command) {
    final relative = command.toLowerCase() == command;
    switch (command.toUpperCase()) {
      case 'M':
        final point = _point(relative);
        path.moveTo(point.dx, point.dy);
        current = start = point;
        _clearReflection();
      case 'L':
        final point = _point(relative);
        path.lineTo(point.dx, point.dy);
        current = point;
        _clearReflection();
      case 'H':
        final x = _number() + (relative ? current.dx : 0);
        path.lineTo(x, current.dy);
        current = Offset(x, current.dy);
        _clearReflection();
      case 'V':
        final y = _number() + (relative ? current.dy : 0);
        path.lineTo(current.dx, y);
        current = Offset(current.dx, y);
        _clearReflection();
      case 'C':
        final c1 = _point(relative);
        final c2 = _point(relative);
        final end = _point(relative);
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        current = end;
        lastCubicControl = c2;
        lastQuadraticControl = null;
      case 'S':
        final c1 = _reflect(lastCubicControl);
        final c2 = _point(relative);
        final end = _point(relative);
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        current = end;
        lastCubicControl = c2;
        lastQuadraticControl = null;
      case 'Q':
        final control = _point(relative);
        final end = _point(relative);
        path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
        current = end;
        lastQuadraticControl = control;
        lastCubicControl = null;
      case 'T':
        final control = _reflect(lastQuadraticControl);
        final end = _point(relative);
        path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
        current = end;
        lastQuadraticControl = control;
        lastCubicControl = null;
      case 'A':
        _arc(relative);
        _clearReflection();
      case 'Z':
        path.close();
        current = start;
        _clearReflection();
      default:
        throw SvgPathParseException('فرمانِ ناشناخته: $command');
    }
  }

  /// کمان‌های SVG با پارامترهای شعاع و زاویه بیان می‌شوند؛ `Path` با مستطیلِ
  /// دربرگیرنده. این تبدیل، پیاده‌سازیِ پیوستِ F.6.5 مشخصه‌ی SVG است.
  void _arc(bool relative) {
    final rx = _number().abs();
    final ry = _number().abs();
    final rotation = _number();
    final largeArc = _flag();
    final sweep = _flag();
    final end = _point(relative);

    if (rx == 0 || ry == 0 || current == end) {
      // درجازده — یک خطِ راست است.
      path.lineTo(end.dx, end.dy);
      current = end;
      return;
    }

    final phi = rotation * math.pi / 180.0;
    final cosPhi = math.cos(phi);
    final sinPhi = math.sin(phi);
    final dx = (current.dx - end.dx) / 2;
    final dy = (current.dy - end.dy) / 2;
    final x1 = cosPhi * dx + sinPhi * dy;
    final y1 = -sinPhi * dx + cosPhi * dy;

    var rxs = rx * rx;
    var rys = ry * ry;
    final lambda = (x1 * x1) / rxs + (y1 * y1) / rys;
    var radiusX = rx;
    var radiusY = ry;
    if (lambda > 1) {
      final scale = math.sqrt(lambda);
      radiusX *= scale;
      radiusY *= scale;
      rxs = radiusX * radiusX;
      rys = radiusY * radiusY;
    }

    final numerator = rxs * rys - rxs * y1 * y1 - rys * x1 * x1;
    final denominator = rxs * y1 * y1 + rys * x1 * x1;
    final factor = math.sqrt(math.max(0, numerator / denominator)) *
        (largeArc == sweep ? -1 : 1);
    final cx1 = factor * radiusX * y1 / radiusY;
    final cy1 = -factor * radiusY * x1 / radiusX;

    final centre = Offset(
      cosPhi * cx1 - sinPhi * cy1 + (current.dx + end.dx) / 2,
      sinPhi * cx1 + cosPhi * cy1 + (current.dy + end.dy) / 2,
    );

    final startAngle = math.atan2((y1 - cy1) / radiusY, (x1 - cx1) / radiusX);
    var deltaAngle = math.atan2((-y1 - cy1) / radiusY, (-x1 - cx1) / radiusX) - startAngle;
    if (!sweep && deltaAngle > 0) {
      deltaAngle -= 2 * math.pi;
    } else if (sweep && deltaAngle < 0) {
      deltaAngle += 2 * math.pi;
    }

    // چرخشِ بیضی را با تبدیلِ ماتریسی می‌آوریم تا `arcTo` دقیق بماند.
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: radiusX * 2,
      height: radiusY * 2,
    );
    final arc = Path()..arcTo(rect, startAngle, deltaAngle, true);
    final transform = Matrix4Rotation(phi, centre);
    path.addPath(arc.transform(transform.storage), Offset.zero);
    current = end;
  }

  Offset _reflect(Offset? control) {
    if (control == null) return current;
    return Offset(2 * current.dx - control.dx, 2 * current.dy - control.dy);
  }

  void _clearReflection() {
    lastCubicControl = null;
    lastQuadraticControl = null;
  }

  Offset _point(bool relative) {
    final x = _number();
    final y = _number();
    return relative ? Offset(current.dx + x, current.dy + y) : Offset(x, y);
  }

  bool _flag() {
    _skipSeparators();
    if (index >= source.length) {
      throw SvgPathParseException('پرچمِ کمان ناتمام است');
    }
    final char = source[index];
    if (char != '0' && char != '1') {
      throw SvgPathParseException('پرچمِ کمان باید ۰ یا ۱ باشد، نه «$char»');
    }
    index++;
    return char == '1';
  }

  double _number() {
    _skipSeparators();
    final begin = index;
    if (index < source.length && (source[index] == '-' || source[index] == '+')) {
      index++;
    }
    while (index < source.length && _isDigit(source[index])) {
      index++;
    }
    if (index < source.length && source[index] == '.') {
      index++;
      while (index < source.length && _isDigit(source[index])) {
        index++;
      }
    }
    if (index < source.length && (source[index] == 'e' || source[index] == 'E')) {
      index++;
      if (index < source.length && (source[index] == '-' || source[index] == '+')) {
        index++;
      }
      while (index < source.length && _isDigit(source[index])) {
        index++;
      }
    }
    final text = source.substring(begin, index);
    final value = double.tryParse(text);
    if (value == null) {
      throw SvgPathParseException('عددِ نامعتبر در جایگاهِ $begin: «$text»');
    }
    return value;
  }

  void _skipSeparators() {
    while (index < source.length) {
      final char = source[index];
      if (char == ' ' || char == ',' || char == '\n' || char == '\r' || char == '\t') {
        index++;
      } else {
        return;
      }
    }
  }

  static bool _isDigit(String char) {
    final code = char.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }

  static bool _isCommand(String char) =>
      'MmLlHhVvCcSsQqTtAaZz'.contains(char);
}

/// چرخشِ حولِ یک نقطه، به‌صورتِ ماتریسِ ۴×۴ ستون‌محور که `Path.transform`
/// می‌خواهد. برای پرهیز از وابستگی به `vector_math` دستی نوشته شده است.
class Matrix4Rotation {
  Matrix4Rotation(double radians, Offset about) {
    final cos = math.cos(radians);
    final sin = math.sin(radians);
    storage = Float64List.fromList(<double>[
      cos, sin, 0, 0, //
      -sin, cos, 0, 0, //
      0, 0, 1, 0, //
      about.dx, about.dy, 0, 1, //
    ]);
  }

  late final Float64List storage;
}
