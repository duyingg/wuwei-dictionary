import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/language/pinyin_utils.dart';
import '../domain/models.dart';

abstract interface class DictionaryRepository {
  Future<ChineseEntry?> findExactCharacter(String character);
  Future<List<ChineseEntry>> findByPinyin(String pinyin);
  Future<List<ChineseEntry>> findByRadical(String radical,
      {int? remainingStrokes});
  Future<List<ChineseEntry>> findByStrokeCount(int count);
  Future<List<ChineseEntry>> findDifficultCharacters();
  Future<List<ChineseEntry>> findByRhyme(String rhyme);
  Future<List<ChineseEntry>> all();
}

class AssetDictionaryRepository implements DictionaryRepository {
  List<ChineseEntry>? _cache;
  Map<String, ChineseEntry>? _byCharacter;

  Future<List<ChineseEntry>> _load() async {
    if (_cache case final value?) return value;
    final raw =
        await rootBundle.loadString('assets/data/chinese_entries_v3.json');
    final decoded = jsonDecode(raw) as List;
    final entries = decoded
        .map((item) => ChineseEntry.fromJson(item as Map<String, dynamic>))
        .where((entry) =>
            entry.character.isNotEmpty &&
            entry.sourceId.isNotEmpty &&
            entry.strokeCount > 0)
        .toList(growable: false);
    assert(
      entries.map((entry) => entry.character).toSet().length == entries.length,
      '字头不可重复',
    );
    _byCharacter = {for (final entry in entries) entry.character: entry};
    return _cache = entries;
  }

  @override
  Future<List<ChineseEntry>> all() => _load();

  @override
  Future<ChineseEntry?> findExactCharacter(String character) async {
    await _load();
    return _byCharacter![character];
  }

  @override
  Future<List<ChineseEntry>> findByPinyin(String pinyin) async {
    final normalized = PinyinUtils.normalize(pinyin);
    return [
      for (final entry in await _load())
        if (entry.pinyin.any((reading) =>
            PinyinUtils.normalize(PinyinUtils.firstSyllable(reading)) ==
            normalized))
          entry,
    ];
  }

  @override
  Future<List<ChineseEntry>> findByRadical(String radical,
      {int? remainingStrokes}) async {
    final entries = await _load();
    final radicalStrokes = _radicalStrokeCount(entries, radical);
    return [
      for (final entry in entries)
        if (entry.radical == radical &&
            (remainingStrokes == null ||
                entry.strokeCount - radicalStrokes == remainingStrokes))
          entry,
    ];
  }

  @override
  Future<List<ChineseEntry>> findByStrokeCount(int count) async => [
        for (final entry in await _load())
          if (entry.strokeCount == count) entry,
      ]..sort((a, b) {
          final radical = RadicalUtils.orderOf(a.radical)
              .compareTo(RadicalUtils.orderOf(b.radical));
          return radical != 0 ? radical : a.character.compareTo(b.character);
        });

  @override
  Future<List<ChineseEntry>> findDifficultCharacters() async => [
        for (final entry in await _load())
          if (entry.difficult ||
              entry.pinyin.any(PinyinUtils.isCompoundReading))
            entry,
      ]..sort((a, b) {
          final stroke = a.strokeCount.compareTo(b.strokeCount);
          return stroke != 0
              ? stroke
              : RadicalUtils.orderOf(a.radical)
                  .compareTo(RadicalUtils.orderOf(b.radical));
        });

  @override
  Future<List<ChineseEntry>> findByRhyme(String rhyme) async => [
        for (final entry in await _load())
          if (entry.pinyin.any((reading) =>
              PinyinUtils.finalOf(PinyinUtils.firstSyllable(reading)) ==
              rhyme.trim()))
            entry,
      ];

  static int _radicalStrokeCount(List<ChineseEntry> entries, String radical) {
    for (final entry in entries) {
      if (entry.character == radical) return entry.strokeCount;
    }
    return 0;
  }
}
