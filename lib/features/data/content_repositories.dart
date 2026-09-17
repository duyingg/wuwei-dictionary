import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/models.dart';

class PolyphonicLearningRepository {
  List<PolyphonicLesson>? _cache;

  Future<List<PolyphonicLesson>> all() async {
    if (_cache case final value?) return value;
    final raw =
        await rootBundle.loadString('assets/data/polyphonic_lessons.json');
    return _cache = (jsonDecode(raw) as List)
        .map((item) => PolyphonicLesson.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}

abstract interface class DailyContentRepository {
  Future<List<DailyContent>> getByType(DailyContentType type);
}

class AssetDailyContentRepository implements DailyContentRepository {
  List<DailyContent>? _cache;

  Future<List<DailyContent>> _load() async {
    if (_cache case final value?) return value;
    final raw = await rootBundle.loadString('assets/data/daily_content.json');
    return _cache = (jsonDecode(raw) as List)
        .map((item) => DailyContent.fromJson(item as Map<String, dynamic>))
        .where((item) => item.id.isNotEmpty && item.sourceId.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<List<DailyContent>> getByType(DailyContentType type) async => [
        for (final item in await _load())
          if (item.type == type) item,
      ];
}

abstract interface class CultureRepository {
  Future<List<CultureItem>> getByCategory(CultureCategory category);
  Future<CultureItem?> getById(String id);
}

class AssetCultureRepository implements CultureRepository {
  List<CultureItem>? _cache;

  Future<List<CultureItem>> _load() async {
    if (_cache case final value?) return value;
    final raw =
        await rootBundle.loadString('assets/data/culture_items_v2.json');
    return _cache = (jsonDecode(raw) as List)
        .map((item) => CultureItem.fromJson(item as Map<String, dynamic>))
        .where((item) => item.id.isNotEmpty && item.sourceId.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<List<CultureItem>> getByCategory(CultureCategory category) async => [
        for (final item in await _load())
          if (item.category == category) item,
      ];

  @override
  Future<CultureItem?> getById(String id) async {
    for (final item in await _load()) {
      if (item.id == id) return item;
    }
    return null;
  }
}

abstract interface class PoetryRepository {
  Future<List<PoetryItem>> all({bool fullLibrary = false});
  Future<PoetryItem?> getById(String id, {bool fullLibrary = false});
}

class AssetPoetryRepository implements PoetryRepository {
  final _cache = <bool, List<PoetryItem>>{};
  final _byId = <bool, Map<String, PoetryItem>>{};

  Future<List<PoetryItem>> _load(bool fullLibrary) async {
    if (_cache[fullLibrary] case final value?) return value;
    final asset = fullLibrary
        ? 'assets/data/poetry_items_full.json'
        : 'assets/data/poetry_items.json';
    final raw = await rootBundle.loadString(asset);
    final items = (jsonDecode(raw) as List)
        .map((item) => PoetryItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    _byId[fullLibrary] = {for (final item in items) item.id: item};
    _cache[fullLibrary] = items;
    return items;
  }

  @override
  Future<List<PoetryItem>> all({bool fullLibrary = false}) =>
      _load(fullLibrary);

  @override
  Future<PoetryItem?> getById(String id, {bool fullLibrary = false}) async {
    await _load(fullLibrary);
    return _byId[fullLibrary]![id];
  }
}
