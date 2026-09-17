import 'dart:convert';
import 'dart:io';

import 'package:wuwei_dictionary/core/language/pinyin_utils.dart';

void main() {
  final curatedFile = File('assets/data/chinese_entries_v2.json');
  final dictionaryFile = File('Aatime/makemeahanzi-master/dictionary.txt');
  final graphicsFile = File('Aatime/makemeahanzi-master/graphics.txt');
  final svgDirectory = Directory('Aatime/makemeahanzi-master/svgs');
  final stCharacters = _readOpenCc('assets/data/opencc/STCharacters.txt');
  final tsCharacters = _readOpenCc('assets/data/opencc/TSCharacters.txt');
  final level1Characters = _readCharacters('Aatime/3500汉字+符号+英文字符集.txt');
  final level2Characters = _readCharacters('Aatime/7000汉字+符号+英文字符集.txt');
  final completePinyin = _readPinyin('assets/data/pinyin_readings.json');

  if (!dictionaryFile.existsSync() || !graphicsFile.existsSync()) {
    stderr.writeln('Make Me a Hanzi source files were not found.');
    exitCode = 1;
    return;
  }

  final curated = <String, Map<String, dynamic>>{};
  if (curatedFile.existsSync()) {
    for (final value in jsonDecode(curatedFile.readAsStringSync()) as List) {
      final item = Map<String, dynamic>.from(value as Map);
      curated[item['character'] as String] = item;
    }
  }
  for (final item in _manualExtras) {
    curated[item['character'] as String] = item;
  }

  final strokeCounts = <String, int>{};
  for (final line in graphicsFile.readAsLinesSync()) {
    final item = jsonDecode(line) as Map<String, dynamic>;
    strokeCounts[item['character'] as String] =
        (item['strokes'] as List).length;
  }

  final output = <Map<String, dynamic>>[];
  final importedCharacters = <String>{};
  for (final line in dictionaryFile.readAsLinesSync()) {
    final source = jsonDecode(line) as Map<String, dynamic>;
    final character = source['character'] as String;
    importedCharacters.add(character);
    final original = curated[character];
    final codePoint = character.runes.first;
    final svgPath = 'Aatime/makemeahanzi-master/svgs/$codePoint.svg';
    final sourcePinyin =
        List<String>.from(source['pinyin'] as List? ?? const []);
    final curatedPinyin =
        List<String>.from(original?['pinyin'] as List? ?? const []);
    final pinyin = <String>{
      ...?completePinyin[character],
      ...sourcePinyin,
      ...curatedPinyin,
    }.toList();
    final strokeCount =
        strokeCounts[character] ?? (original?['strokeCount'] as int? ?? 0);
    final senses = List<dynamic>.from(original?['senses'] as List? ?? const []);
    final traditionalForms = <String>{
      ...?stCharacters[character],
      if (original?['traditional'] case final String value) value,
    }..remove(character);
    final simplifiedForms = <String>{...?tsCharacters[character]}
      ..remove(character);
    final hasSimplifiedRelation = traditionalForms.isNotEmpty;
    final hasTraditionalRelation = simplifiedForms.isNotEmpty;
    final script = hasSimplifiedRelation && !hasTraditionalRelation
        ? 'simplified'
        : hasTraditionalRelation && !hasSimplifiedRelation
            ? 'traditional'
            : 'common';
    final relatedCharacters = <String>{
      character,
      ...traditionalForms,
      ...simplifiedForms,
    };
    final characterLevel = relatedCharacters.any(level1Characters.contains)
        ? 1
        : relatedCharacters.any(level2Characters.contains)
            ? 2
            : 3;
    final radical =
        source['radical'] as String? ?? original?['radical'] as String? ?? '';

    output.add({
      'character': character,
      'pinyin': pinyin,
      'radical': radical,
      'strokeCount': strokeCount,
      'structure': original?['structure'] as String? ??
          _structureOf(source['decomposition'] as String?),
      'unicode':
          'U+${codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}',
      'traditional': original?['traditional'],
      'variants':
          List<dynamic>.from(original?['variants'] as List? ?? const []),
      'senses': senses,
      'difficult': _isDifficultRadical(radical),
      'decomposition': source['decomposition'] as String?,
      'strokeOrderAsset': File(svgPath).existsSync() ? svgPath : null,
      'script': script,
      'simplifiedForms': simplifiedForms.toList(),
      'traditionalForms': traditionalForms.toList(),
      'characterLevel': characterLevel,
      'sourceId': senses.isEmpty ? 'makemeahanzi' : 'makemeahanzi+app-original',
    });
  }

  for (final entry in curated.values) {
    final character = entry['character'] as String;
    if (!importedCharacters.contains(character)) {
      final relatedCharacters = <String>{
        character,
        ...List<String>.from(entry['variants'] as List? ?? const []),
      };
      final characterLevel = relatedCharacters.any(level1Characters.contains)
          ? 1
          : relatedCharacters.any(level2Characters.contains)
              ? 2
              : 3;
      output.add({
        ...entry,
        'script': entry['script'] ?? 'common',
        'simplifiedForms': entry['simplifiedForms'] ?? const <String>[],
        'traditionalForms': entry['traditionalForms'] ?? const <String>[],
        'characterLevel': characterLevel,
        'difficult': _isDifficultRadical(entry['radical'] as String? ?? ''),
      });
    }
  }

  output.sort((a, b) => (a['character'] as String)
      .runes
      .first
      .compareTo((b['character'] as String).runes.first));
  curatedFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(output)}\n');

  stdout.writeln('Imported ${output.length} entries.');
  stdout.writeln(
      'Stroke SVGs: ${svgDirectory.listSync().whereType<File>().length}');
  stdout.writeln(
      'Entries with Chinese built-in senses: ${output.where((e) => (e['senses'] as List).isNotEmpty).length}');
}

Set<String> _readCharacters(String path) {
  final file = File(path);
  if (!file.existsSync()) return const {};
  return file.readAsStringSync().runes.map(String.fromCharCode).toSet();
}

bool _isDifficultRadical(String radical) {
  if (radical.isEmpty || radical == '？') return true;
  return !RadicalUtils.isStandard(radical);
}

Map<String, List<String>> _readOpenCc(String path) {
  final file = File(path);
  if (!file.existsSync()) return const {};
  final result = <String, List<String>>{};
  for (final line in file.readAsLinesSync()) {
    if (line.isEmpty || line.startsWith('#')) continue;
    final fields = line.split('\t');
    if (fields.length < 2) continue;
    result[fields.first] = fields[1].split(' ');
  }
  return result;
}

Map<String, List<String>> _readPinyin(String path) {
  final file = File(path);
  if (!file.existsSync()) return const {};
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final item in decoded.entries)
      item.key: List<String>.from(item.value as List),
  };
}

String _structureOf(String? decomposition) {
  if (decomposition == null ||
      decomposition.isEmpty ||
      decomposition.startsWith('？')) {
    return '独体或未知结构';
  }
  return switch (decomposition.runes.first) {
    0x2FF0 || 0x2FF2 => '左右结构',
    0x2FF1 || 0x2FF3 => '上下结构',
    >= 0x2FF4 && <= 0x2FFA => '包围结构',
    _ => '独体结构',
  };
}

final _manualExtras = <Map<String, dynamic>>[
  {
    'character': '𠮷',
    'pinyin': ['jí'],
    'radical': '口',
    'strokeCount': 6,
    'structure': '上下结构',
    'unicode': 'U+20BB7',
    'traditional': null,
    'variants': ['吉'],
    'senses': [
      {
        'definition': '“吉”的异体字，常见于日本人名。',
        'examples': <String>[],
      }
    ],
    'difficult': true,
    'decomposition': null,
    'strokeOrderAsset': null,
    'sourceId': 'app-original',
  },
  {
    'character': '龘',
    'pinyin': ['dá'],
    'radical': '龍',
    'strokeCount': 48,
    'structure': '品字结构',
    'unicode': 'U+9F98',
    'traditional': null,
    'variants': <String>[],
    'senses': [
      {
        'definition': '群龙腾飞的样子。',
        'examples': <String>[],
      }
    ],
    'difficult': true,
    'decomposition': null,
    'strokeOrderAsset': null,
    'sourceId': 'app-original',
  },
];
