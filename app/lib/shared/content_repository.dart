// بارگذاریِ محتوا از دارایی‌های همراهِ اپ.
//
// آفلاین‌اول، بی‌استثنا (بخش ۹٫۴): همه‌ی محتوا با اپ بسته‌بندی می‌شود و هیچ
// درخواستِ شبکه‌ای برای خواندنِ یک واژه زده نمی‌شود.
//
// `content/` در ریشه‌ی مخزن است و بیرون از بسته‌ی Flutter؛ `make content-sync`
// آن را در `app/assets/content/` می‌گذارد. فهرستِ نام‌ها از AssetManifest
// خوانده می‌شود تا افزودنِ یک واژه هیچ تغییری در کد نخواهد.

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaml/yaml.dart';

import 'models.dart';

const _root = 'assets/content';

class ContentBundle {
  const ContentBundle({
    required this.words,
    required this.khans,
    required this.verses,
    required this.noEquivalents,
  });

  /// همه‌ی واژه‌ها، کلید = شناسه.
  final Map<String, Word> words;
  final List<Khan> khans;
  final List<Verse> verses;
  final List<NoEquivalent> noEquivalents;

  Word? word(String id) => words[id];

  List<Word> wordsOf(Station station) => [
        for (final id in station.wordIds)
          if (words[id] case final word?) word,
      ];

  /// بیت‌هایی که برای «بیت‌یاب» به کار می‌آیند: هم واژه‌شان را می‌شناسیم و هم
  /// جای خالی دارند.
  List<Verse> versesFor(String wordId) =>
      [for (final v in verses) if (v.isUsable && v.wordId == wordId) v];

  /// اگر کاربر وام‌واژه‌ای را بجوید که برابر ندارد.
  NoEquivalent? noEquivalentFor(String loan) {
    for (final entry in noEquivalents) {
      if (entry.loan == loan) return entry;
    }
    return null;
  }
}

class ContentRepository {
  const ContentRepository(this._bundle);
  final AssetBundle _bundle;

  Future<ContentBundle> load() async {
    final manifest = await _manifest();

    final words = <String, Word>{};
    for (final path in manifest.where((p) => p.startsWith('$_root/words/'))) {
      final yaml = loadYaml(await _bundle.loadString(path)) as Map<dynamic, dynamic>;
      final word = Word.fromYaml(yaml);
      words[word.id] = word;
    }

    final khans = <Khan>[];
    for (final path in manifest.where((p) => p.startsWith('$_root/lessons/'))) {
      final yaml = loadYaml(await _bundle.loadString(path)) as Map<dynamic, dynamic>;
      khans.add(Khan.fromYaml(yaml));
    }
    khans.sort((a, b) => a.number.compareTo(b.number));

    final verses = <Verse>[];
    for (final path in manifest.where((p) => p.startsWith('$_root/corpus/'))) {
      final yaml = loadYaml(await _bundle.loadString(path)) as Map<dynamic, dynamic>;
      final defaultMeter = yaml['meter_default'] as String?;
      for (final raw in (yaml['verses'] as List<dynamic>? ?? const [])) {
        final verse = Verse.tryFromYaml(
          raw as Map<dynamic, dynamic>,
          defaultMeter: defaultMeter,
        );
        if (verse != null) verses.add(verse);
      }
    }

    final noEquivalents = <NoEquivalent>[];
    final noEquivalentPath = '$_root/NO_EQUIVALENT.yaml';
    if (manifest.contains(noEquivalentPath)) {
      final yaml = loadYaml(await _bundle.loadString(noEquivalentPath)) as Map<dynamic, dynamic>;
      for (final raw in (yaml['entries'] as List<dynamic>? ?? const [])) {
        noEquivalents.add(NoEquivalent.fromYaml(raw as Map<dynamic, dynamic>));
      }
    }

    return ContentBundle(
      words: words,
      khans: khans,
      verses: verses,
      noEquivalents: noEquivalents,
    );
  }

  /// نامِ همه‌ی دارایی‌های YAML.
  ///
  /// از `AssetManifest` می‌آید نه از `AssetManifest.json` — آن فایل از
  /// Flutter 3.16 برداشته شده و جایش صورتِ دودویی نشسته است.
  Future<List<String>> _manifest() async {
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    return manifest.listAssets().where((k) => k.endsWith('.yaml')).toList()..sort();
  }
}

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepository(rootBundle),
);

/// محتوا یک بار خوانده می‌شود و تا پایانِ عمرِ اپ می‌ماند.
final contentProvider = FutureProvider<ContentBundle>(
  (ref) => ref.watch(contentRepositoryProvider).load(),
);
