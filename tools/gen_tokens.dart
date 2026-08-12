// tokens.json → Dart
//
//   dart run tools/gen_tokens.dart           # بازتولید
//   dart run tools/gen_tokens.dart --check   # تنها می‌سنجد؛ برای CI
//
// design/tokens.json منبعِ یگانه‌ی حقیقت است (بخش ۹٫۴). هیچ رنگ، اندازه یا
// منحنی‌ای در ویجت‌ها هارد‌کد نمی‌شود — همه از اینجا می‌آید. CI هم می‌سنجد که
// فایلِ تولیدشده با tokens.json هم‌خوان است و هم اینکه ویجتی رنگِ خام ننوشته.

import 'dart:convert';
import 'dart:io';

const _source = 'design/tokens.json';
const _target = 'app/lib/design/tokens.g.dart';

void main(List<String> args) {
  final root = _repoRoot();
  final sourceFile = File('$root/$_source');
  if (!sourceFile.existsSync()) {
    stderr.writeln('$_source یافت نشد');
    exit(1);
  }

  final tokens = jsonDecode(sourceFile.readAsStringSync()) as Map<String, dynamic>;
  final generated = _render(tokens);
  final targetFile = File('$root/$_target');

  if (args.contains('--check')) {
    final current = targetFile.existsSync() ? targetFile.readAsStringSync() : '';
    if (current == generated) {
      stdout.writeln('✓ $_target با $_source هم‌خوان است.');
      exit(0);
    }
    stderr.writeln('✗ $_target کهنه است. اجرا کنید: dart run tools/gen_tokens.dart');
    exit(1);
  }

  targetFile.parent.createSync(recursive: true);
  targetFile.writeAsStringSync(generated);
  stdout.writeln('✓ $_target نوشته شد.');
}

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/$_source').existsSync()) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current.path;
    dir = parent;
  }
}

/// `#RRGGBB` یا `#RRGGBBAA` → `Color(0xAARRGGBB)`
String _color(String hex) {
  var value = hex.replaceFirst('#', '').toUpperCase();
  if (value.length == 6) value = '${value}FF';
  if (value.length != 8) throw FormatException('رنگِ نامعتبر: $hex');
  final rgb = value.substring(0, 6);
  final alpha = value.substring(6, 8);
  return 'Color(0x$alpha$rgb)';
}

/// `{palette.firuzeKashi}` → مقدارِ همان کلید
String _resolve(String value, Map<String, dynamic> palette) {
  if (!value.startsWith('{') || !value.endsWith('}')) return value;
  final key = value.substring(1, value.length - 1).split('.').last;
  final entry = palette[key] as Map<String, dynamic>?;
  if (entry == null) throw FormatException('ارجاعِ ناشناخته: $value');
  return entry['value'] as String;
}

String _num(num value) => value is int ? '$value.0' : '$value';

String _render(Map<String, dynamic> tokens) {
  final palette = tokens['palette'] as Map<String, dynamic>;
  final colors = tokens['color'] as Map<String, dynamic>;
  final dark = colors['dark'] as Map<String, dynamic>;
  final light = colors['light'] as Map<String, dynamic>;
  final type = tokens['typeScale'] as Map<String, dynamic>;
  final steps = type['steps'] as Map<String, dynamic>;
  final space = tokens['space'] as Map<String, dynamic>;
  final radius = tokens['radius'] as Map<String, dynamic>;
  final opacity = tokens['opacity'] as Map<String, dynamic>;
  final motion = tokens['motion'] as Map<String, dynamic>;
  final curves = motion['curve'] as Map<String, dynamic>;
  final durations = motion['duration'] as Map<String, dynamic>;
  final spring = (motion['spring'] as Map<String, dynamic>)['progressBar'] as Map<String, dynamic>;
  final shake = motion['shake'] as Map<String, dynamic>;
  final fonts = tokens['font'] as Map<String, dynamic>;
  final a11y = tokens['a11y'] as Map<String, dynamic>;
  final signature = (tokens['signature'] as Map<String, dynamic>)['noreVajeh'] as Map<String, dynamic>;
  final meta = tokens['meta'] as Map<String, dynamic>;

  final out = StringBuffer()
    ..writeln('// GENERATED FILE — دست نزنید.')
    ..writeln('//')
    ..writeln('// منبع:      $_source')
    ..writeln('// سازنده:    tools/gen_tokens.dart')
    ..writeln('// بازتولید:  dart run tools/gen_tokens.dart')
    ..writeln('//')
    ..writeln('// زبانِ طراحی: ${meta['name']}  ·  نسخه: ${meta['version']}')
    ..writeln()
    ..writeln("import 'package:flutter/painting.dart';")
    ..writeln()
    ..writeln('/// رنگ‌های یک پوسته. دو نمونه دارد: [dark] و [light].')
    ..writeln('class SarehColors {')
    ..writeln('  const SarehColors({');
  for (final key in dark.keys) {
    out.writeln('    required this.$key,');
  }
  out
    ..writeln('  });')
    ..writeln();
  for (final key in dark.keys) {
    out.writeln('  final Color $key;');
  }
  for (final theme in [('dark', dark), ('light', light)]) {
    out
      ..writeln()
      ..writeln('  static const SarehColors ${theme.$1} = SarehColors(');
    for (final entry in theme.$2.entries) {
      out.writeln('    ${entry.key}: ${_color(_resolve(entry.value as String, palette))},');
    }
    out.writeln('  );');
  }
  out
    ..writeln('}')
    ..writeln()
    ..writeln('/// مقیاسِ تایپ. `Line` ارتفاعِ خط است و هرگز زیر ۱٫۷ نمی‌رود.')
    ..writeln('class SarehType {');
  for (final entry in steps.entries) {
    final step = entry.value as Map<String, dynamic>;
    out
      ..writeln('  static const double ${entry.key} = ${_num(step['size'] as num)};')
      ..writeln('  static const double ${entry.key}Line = ${_num(step['lineHeight'] as num)};');
  }
  out
    ..writeln()
    ..writeln("  static const String displayFamily = '${(fonts['display'] as Map)['family']}';")
    ..writeln("  static const String bodyFamily = '${(fonts['body'] as Map)['family']}';")
    ..writeln("  static const String dyslexicFamily = '${(fonts['dyslexic'] as Map)['family']}';")
    ..writeln('  static const double dyslexicLetterSpacing = '
        '${_num((fonts['dyslexic'] as Map)['letterSpacing'] as num)};')
    ..writeln('}')
    ..writeln()
    ..writeln('/// فاصله‌ها.')
    ..writeln('class SarehSpace {');
  for (final entry in space.entries) {
    out.writeln('  static const double ${entry.key} = ${_num(entry.value as num)};');
  }
  out
    ..writeln('}')
    ..writeln()
    ..writeln('/// شعاعِ گوشه‌ها. کارت‌ها [card]، دکمه‌ها [capsule]، ورودی‌ها [input].')
    ..writeln('class SarehRadius {');
  for (final entry in radius.entries) {
    out.writeln('  static const double ${entry.key} = ${_num(entry.value as num)};');
  }
  out
    ..writeln('}')
    ..writeln()
    ..writeln('/// کدری‌ها.')
    ..writeln('class SarehOpacity {');
  for (final entry in opacity.entries) {
    out.writeln('  static const double ${entry.key} = ${_num(entry.value as num)};');
  }
  out
    ..writeln('}')
    ..writeln()
    ..writeln('/// منحنی‌ها و زمان‌بندی‌ها.')
    ..writeln('class SarehMotion {');
  for (final entry in curves.entries) {
    final cubic = (entry.value as Map<String, dynamic>)['cubic'] as List<dynamic>;
    final args = cubic.map((v) => _num(v as num)).join(', ');
    out.writeln('  static const Cubic ${entry.key} = Cubic($args);');
  }
  out.writeln();
  for (final entry in durations.entries) {
    final spec = entry.value as Map<String, dynamic>;
    out.writeln('  static const Duration ${entry.key} = '
        'Duration(milliseconds: ${spec['ms']});');
  }
  out.writeln();
  for (final entry in durations.entries) {
    final spec = entry.value as Map<String, dynamic>;
    out.writeln('  static const Cubic ${entry.key}Curve = ${spec['curve']};');
  }
  out
    ..writeln()
    ..writeln('  static const double springStiffness = ${_num(spring['stiffness'] as num)};')
    ..writeln('  static const double springDamping = ${_num(spring['damping'] as num)};')
    ..writeln('  static const double springMass = ${_num(spring['mass'] as num)};')
    ..writeln('  static const double shakeAmplitude = ${_num(shake['amplitude'] as num)};')
    ..writeln('  static const int shakeCycles = ${shake['cycles']};')
    ..writeln('  static const Duration shake = Duration(milliseconds: ${shake['ms']});')
    ..writeln('}')
    ..writeln()
    ..writeln('/// دسترس‌پذیری.')
    ..writeln('class SarehA11y {')
    ..writeln('  static const double minTouchTarget = ${_num(a11y['minTouchTarget'] as num)};')
    ..writeln('}')
    ..writeln()
    ..writeln('/// عنصرِ امضا — «نورِ واژه».')
    ..writeln('class SarehSignature {')
    ..writeln('  static const Duration startDelay = '
        'Duration(milliseconds: ${signature['startDelayMs']});')
    ..writeln('  static const Duration duration = '
        'Duration(milliseconds: ${signature['durationMs']});')
    ..writeln('  static const double strokeWidth = ${_num(signature['strokeWidth'] as num)};')
    ..writeln('  static const double glowSigma = ${_num(signature['glowSigma'] as num)};')
    ..writeln('  static const double trailFraction = ${_num(signature['trailFraction'] as num)};');
  final particles = signature['goldParticles'] as Map<String, dynamic>;
  out
    ..writeln('  static const int particleCount = ${particles['count']};')
    ..writeln('  static const Duration particleAt = '
        'Duration(milliseconds: ${particles['atMs']});')
    ..writeln('  static const double particleRise = ${_num(particles['riseDp'] as num)};')
    ..writeln('  static const Duration particleFade = '
        'Duration(milliseconds: ${particles['fadeMs']});')
    ..writeln('}');
  return out.toString();
}
