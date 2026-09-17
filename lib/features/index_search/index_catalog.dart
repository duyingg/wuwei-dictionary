import '../../core/language/pinyin_utils.dart';
import '../domain/character_visibility.dart';
import '../domain/models.dart';

class IndexCatalog {
  IndexCatalog(List<ChineseEntry> source,
      {this.display = ScriptDisplay.simplified, this.maxLevel = 3})
      : entries = List.unmodifiable(source.where(
          (entry) => entry.isVisibleFor(
            display: display,
            maxLevel: maxLevel,
          ),
        )),
        _byCharacter = {for (final entry in source) entry.character: entry};

  final List<ChineseEntry> entries;
  final ScriptDisplay display;
  final int maxLevel;
  final Map<String, ChineseEntry> _byCharacter;

  Map<String, List<String>> get pronunciationsByInitial {
    final groups = <String, Set<String>>{};
    for (final entry in entries) {
      for (final pinyin in entry.pinyin) {
        final first = PinyinUtils.firstSyllable(pinyin);
        final section = PinyinUtils.sectionOf(first);
        if (section.isNotEmpty) {
          groups
              .putIfAbsent(section, () => {})
              .add(PinyinUtils.displaySyllable(first));
        }
      }
    }
    return {
      for (final initial in PinyinUtils.pinyinSections)
        if (groups[initial]?.isNotEmpty ?? false)
          initial: _sortReadings(groups[initial]!),
    };
  }

  Map<String, List<String>> get pronunciationsByFinal {
    final groups = <String, Set<String>>{};
    for (final entry in entries) {
      for (final pinyin in entry.pinyin) {
        final first = PinyinUtils.firstSyllable(pinyin);
        final finalValue = PinyinUtils.finalOf(first);
        if (finalValue.isNotEmpty) {
          groups
              .putIfAbsent(finalValue, () => {})
              .add(PinyinUtils.displaySyllable(first));
        }
      }
    }
    final keys = groups.keys.toList()
      ..sort((a, b) => _finalOrder(a).compareTo(_finalOrder(b)));
    return {for (final key in keys) key: _sortReadings(groups[key]!)};
  }

  Map<int, List<ChineseEntry>> entriesForSyllable(String syllable) {
    final normalized = PinyinUtils.normalize(syllable);
    final groups = <int, Set<ChineseEntry>>{};
    for (final entry in entries) {
      for (final reading in entry.pinyin) {
        final first = PinyinUtils.firstSyllable(reading);
        if (PinyinUtils.normalize(first) == normalized) {
          groups.putIfAbsent(PinyinUtils.toneOf(first), () => {}).add(entry);
        }
      }
    }
    return {
      for (final tone in [1, 2, 3, 4, 5])
        if (groups[tone]?.isNotEmpty ?? false)
          tone: groups[tone]!.toList()..sort(_entryOrder),
    };
  }

  Map<int, List<String>> readingsForSyllable(String syllable) {
    final normalized = PinyinUtils.normalize(syllable);
    final groups = <int, Set<String>>{};
    for (final entry in entries) {
      for (final reading in entry.pinyin) {
        final first = PinyinUtils.firstSyllable(reading);
        if (PinyinUtils.normalize(first) == normalized) {
          groups.putIfAbsent(PinyinUtils.toneOf(first), () => {}).add(first);
        }
      }
    }
    return {
      for (final item in groups.entries) item.key: item.value.toList()..sort(),
    };
  }

  Map<int, List<String>> get radicalsByStroke {
    final groups = <int, Set<String>>{};
    for (final entry in entries) {
      if (entry.radical.isEmpty) continue;
      final count = radicalStrokeCount(entry.radical);
      if (count <= 0) continue;
      groups.putIfAbsent(count, () => {}).add(entry.radical);
    }
    final keys = groups.keys.toList()..sort();
    return {
      for (final key in keys)
        key: groups[key]!.toList()
          ..sort((a, b) =>
              RadicalUtils.orderOf(a).compareTo(RadicalUtils.orderOf(b))),
    };
  }

  int radicalStrokeCount(String radical) =>
      _byCharacter[radical]?.strokeCount ?? 0;

  String? strokeAssetForCharacter(String character) =>
      _byCharacter[character]?.strokeOrderAsset;

  Map<int, List<ChineseEntry>> entriesForRadical(String radical) {
    final radicalStrokes = radicalStrokeCount(radical);
    final groups = <int, List<ChineseEntry>>{};
    for (final entry in entries) {
      if (entry.radical != radical) continue;
      final remaining = entry.strokeCount - radicalStrokes;
      groups.putIfAbsent(remaining < 0 ? 0 : remaining, () => []).add(entry);
    }
    for (final values in groups.values) {
      values.sort((a, b) => a.character.compareTo(b.character));
    }
    return Map.fromEntries(
        groups.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  List<int> get strokeCounts {
    final values = entries
        .where((entry) => entry.pinyin.isNotEmpty)
        .map((entry) => entry.strokeCount)
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  List<ChineseEntry> entriesForStrokeCount(int count) {
    final values = [
      for (final entry in entries)
        if (entry.strokeCount == count && entry.pinyin.isNotEmpty) entry,
    ];
    values.sort(_entryOrder);
    return values;
  }

  Map<int, List<ChineseEntry>> get difficultByStroke {
    final groups = <int, List<ChineseEntry>>{};
    final compound = entries
        .where((entry) => entry.pinyin.any(PinyinUtils.isCompoundReading))
        .toList()
      ..sort(_entryOrder);
    if (compound.isNotEmpty) groups[0] = compound;
    for (final entry in entries.where(
      (entry) =>
          entry.difficult &&
          entry.pinyin.isNotEmpty &&
          !entry.pinyin.any(PinyinUtils.isCompoundReading),
    )) {
      groups.putIfAbsent(entry.strokeCount, () => []).add(entry);
    }
    for (final values in groups.values) {
      values.sort(_entryOrder);
    }
    return Map.fromEntries(
        groups.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  static List<String> _sortReadings(Set<String> values) => values.toList()
    ..sort((a, b) {
      final plain =
          PinyinUtils.normalize(a).compareTo(PinyinUtils.normalize(b));
      return plain != 0 ? plain : a.compareTo(b);
    });

  static int _entryOrder(ChineseEntry a, ChineseEntry b) {
    final radical = RadicalUtils.orderOf(a.radical)
        .compareTo(RadicalUtils.orderOf(b.radical));
    if (radical != 0) return radical;
    return a.character.compareTo(b.character);
  }

  static int _finalOrder(String value) {
    const base = ['a', 'o', 'e', 'i', 'u', 'v'];
    final first = base.indexOf(value[0]);
    return (first < 0 ? 9 : first) * 1000 +
        value.codeUnits.fold(0, (a, b) => a + b);
  }
}
