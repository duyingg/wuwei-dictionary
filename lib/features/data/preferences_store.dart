import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/design/bundled_skin_loader.dart';
import '../domain/models.dart';

abstract final class PreferencesKeys {
  static const dailyType = 'v1.settings.dailyContentType';
  static const fontScale = 'v1.settings.fontScale';
  static const keepHistory = 'v1.settings.keepSearchHistory';
  static const autofocus = 'v1.settings.autofocusAfterClear';
  static const reduceDecoration = 'v1.settings.reduceDecoration';
  static const fullPoetryLibrary = 'v1.settings.fullPoetryLibrary';
  static const scriptDisplay = 'v1.settings.scriptDisplay';
  static const maxCharacterLevel = 'v1.settings.maxCharacterLevel';
  static const skin = 'v1.settings.skin';
  static const importedSkin = 'v1.settings.importedSkin';
  static const activeImportedSkin = 'v2.settings.activeImportedSkin';
  static const sidebarWidth = 'v1.settings.sidebarWidth';
  static const favorites = 'v1.favorites.characters';
  static const searchHistory = 'v1.searchHistory.characters';
  static const defaultSkinSeeded = 'v1.skin.defaultSeeded';
  static const bundledSkinsSeeded = 'v2.skin.bundledSeeded';
}

class PreferencesStore {
  static const _skinBoxName = 'skin_packages';
  static const _skinBoxKey = 'active_imported_skin';
  static const _skinsBoxKey = 'imported_skins_v2';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final skinBox =
        Hive.isBoxOpen(_skinBoxName) ? Hive.box<String>(_skinBoxName) : null;
    final legacySkinJson = prefs.getString(PreferencesKeys.importedSkin);
    final storedSkinsJson =
        skinBox?.get(_skinsBoxKey) ?? prefs.getString(_skinsBoxKey);
    final importedSkins = _decodeSkinList(storedSkinsJson);
    final legacyStoredJson = skinBox?.get(_skinBoxKey) ?? legacySkinJson;
    final legacySkin = _decodeSkin(legacyStoredJson);
    if (legacySkin != null &&
        !importedSkins.any((skin) => skin.name == legacySkin.name)) {
      importedSkins.add(legacySkin);
    }
    if (prefs.getBool(PreferencesKeys.bundledSkinsSeeded) != true) {
      try {
        for (final bundledSkin in await BundledSkinLoader.loadAll()) {
          final index = importedSkins.indexWhere(
            (skin) => skin.name == bundledSkin.name,
          );
          if (index < 0) {
            importedSkins.add(bundledSkin);
          } else {
            importedSkins[index] = bundledSkin;
          }
        }
      } on Object {
        // 捆绑皮肤不能阻塞启动；内置宣纸皮肤继续作为最终回退。
      } finally {
        await prefs.setBool(PreferencesKeys.bundledSkinsSeeded, true);
      }
    }
    await _saveSkins(importedSkins, prefs, skinBox);
    final storedSkin = prefs.getString(PreferencesKeys.skin) ?? 'parchment';
    final selectedSkin =
        AppSkin.values.where((value) => value.name == storedSkin).firstOrNull;
    final activeName =
        prefs.getString(PreferencesKeys.activeImportedSkin) ?? legacySkin?.name;
    final importedSkin = importedSkins
            .where((skin) => skin.name == activeName)
            .firstOrNull ??
        (selectedSkin == AppSkin.imported ? importedSkins.firstOrNull : null);
    return AppSettings(
      dailyContentType: DailyContentType.values
          .byName(prefs.getString(PreferencesKeys.dailyType) ?? 'character'),
      fontScale: AppFontScale.values
          .byName(prefs.getString(PreferencesKeys.fontScale) ?? 'standard'),
      keepSearchHistory: prefs.getBool(PreferencesKeys.keepHistory) ?? true,
      autofocusAfterClear: prefs.getBool(PreferencesKeys.autofocus) ?? true,
      reduceDecoration:
          prefs.getBool(PreferencesKeys.reduceDecoration) ?? false,
      fullPoetryLibrary:
          prefs.getBool(PreferencesKeys.fullPoetryLibrary) ?? false,
      scriptDisplay: ScriptDisplay.values.byName(
        prefs.getString(PreferencesKeys.scriptDisplay) ?? 'simplified',
      ),
      maxCharacterLevel:
          (prefs.getInt(PreferencesKeys.maxCharacterLevel) ?? 3).clamp(1, 3),
      skin: selectedSkin == AppSkin.imported && importedSkin == null
          ? AppSkin.parchment
          : selectedSkin ?? AppSkin.parchment,
      importedSkin: importedSkin,
      importedSkins: importedSkins,
      sidebarWidth: (prefs.getDouble(PreferencesKeys.sidebarWidth) ?? 68)
          .clamp(48, 120)
          .toDouble(),
    );
  }

  Future<void> saveSettings(AppSettings value) async {
    final prefs = await SharedPreferences.getInstance();
    final skinBox =
        Hive.isBoxOpen(_skinBoxName) ? Hive.box<String>(_skinBoxName) : null;
    final skinStorage = _saveSkins(value.importedSkins, prefs, skinBox);
    await Future.wait([
      prefs.setString(PreferencesKeys.dailyType, value.dailyContentType.name),
      prefs.setString(PreferencesKeys.fontScale, value.fontScale.name),
      prefs.setBool(PreferencesKeys.keepHistory, value.keepSearchHistory),
      prefs.setBool(PreferencesKeys.autofocus, value.autofocusAfterClear),
      prefs.setBool(PreferencesKeys.reduceDecoration, value.reduceDecoration),
      prefs.setBool(PreferencesKeys.fullPoetryLibrary, value.fullPoetryLibrary),
      prefs.setString(PreferencesKeys.scriptDisplay, value.scriptDisplay.name),
      prefs.setInt(PreferencesKeys.maxCharacterLevel, value.maxCharacterLevel),
      prefs.setString(PreferencesKeys.skin, value.skin.name),
      value.importedSkin == null
          ? prefs.remove(PreferencesKeys.activeImportedSkin)
          : prefs.setString(
              PreferencesKeys.activeImportedSkin,
              value.importedSkin!.name,
            ),
      skinStorage,
      prefs.setDouble(
        PreferencesKeys.sidebarWidth,
        value.sidebarWidth.clamp(48, 120),
      ),
    ]);
  }

  Future<void> _saveSkins(List<ImportedSkin> skins, SharedPreferences prefs,
      Box<String>? box) async {
    final encoded = jsonEncode([
      for (final skin in skins) skin.toJson(),
    ]);
    if (box == null) {
      await prefs.setString(_skinsBoxKey, encoded);
    } else {
      await box.put(_skinsBoxKey, encoded);
      await prefs.remove(_skinsBoxKey);
      await box.delete(_skinBoxKey);
    }
    await prefs.remove(PreferencesKeys.importedSkin);
  }

  List<ImportedSkin> _decodeSkinList(String? value) {
    if (value == null) return [];
    try {
      return [
        for (final item in jsonDecode(value) as List)
          ImportedSkin.fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } on Object {
      return [];
    }
  }

  ImportedSkin? _decodeSkin(String? value) {
    if (value == null) return null;
    try {
      return ImportedSkin.fromJson(
        Map<String, dynamic>.from(jsonDecode(value) as Map),
      );
    } on Object {
      return null;
    }
  }

  Future<Set<String>> loadFavorites() async =>
      (await SharedPreferences.getInstance())
          .getStringList(PreferencesKeys.favorites)
          ?.toSet() ??
      {};

  Future<void> saveFavorites(Set<String> values) async =>
      (await SharedPreferences.getInstance())
          .setStringList(PreferencesKeys.favorites, values.toList());

  Future<List<String>> loadSearchHistory() async =>
      (await SharedPreferences.getInstance())
          .getStringList(PreferencesKeys.searchHistory) ??
      const [];

  Future<void> saveSearchHistory(List<String> values) async =>
      (await SharedPreferences.getInstance()).setStringList(
        PreferencesKeys.searchHistory,
        values.take(100).toList(),
      );
}
