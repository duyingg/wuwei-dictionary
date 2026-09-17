import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/data/repositories.dart';
import '../features/domain/character_visibility.dart';
import '../features/domain/models.dart';

final dictionaryRepositoryProvider =
    Provider<DictionaryRepository>((ref) => AssetDictionaryRepository());
final dailyContentRepositoryProvider =
    Provider<DailyContentRepository>((ref) => AssetDailyContentRepository());
final cultureRepositoryProvider =
    Provider<CultureRepository>((ref) => AssetCultureRepository());
final poetryRepositoryProvider =
    Provider<PoetryRepository>((ref) => AssetPoetryRepository());
final polyphonicLearningRepositoryProvider =
    Provider((ref) => PolyphonicLearningRepository());
final polyphonicLessonsProvider = FutureProvider<List<PolyphonicLesson>>(
  (ref) => ref.read(polyphonicLearningRepositoryProvider).all(),
);
final polyphonicChallengeLevelProvider = StateProvider<int>((ref) => 0);
final polyphonicEndlessCorrectProvider = StateProvider<int>((ref) => 0);
final preferencesStoreProvider = Provider((ref) => PreferencesStore());
final dailyContentServiceProvider =
    Provider((ref) => const DailyContentService());
final dailyRerollProvider = StateProvider<int>((ref) => 0);
final cultureDisplayModeProvider =
    StateProvider<CultureDisplayMode?>((ref) => null);

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() =>
      ref.read(preferencesStoreProvider).loadSettings();

  Future<void> setSettings(AppSettings Function(AppSettings) change) async {
    final previous = state.valueOrNull ?? const AppSettings();
    final next = change(previous);
    state = AsyncData(next);
    try {
      await ref.read(preferencesStoreProvider).saveSettings(next);
      ref.read(dailyRerollProvider.notifier).state = 0;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> reset() => setSettings(
        (current) => AppSettings(importedSkins: current.importedSkins),
      );
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
        SettingsController.new);

class FavoritesController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() =>
      ref.read(preferencesStoreProvider).loadFavorites();

  Future<void> toggle(String value) async {
    final next = {...?state.valueOrNull};
    next.contains(value) ? next.remove(value) : next.add(value);
    state = AsyncData(next);
    await ref.read(preferencesStoreProvider).saveFavorites(next);
  }

  Future<void> clear() async {
    state = const AsyncData({});
    await ref.read(preferencesStoreProvider).saveFavorites({});
  }
}

final favoritesControllerProvider =
    AsyncNotifierProvider<FavoritesController, Set<String>>(
        FavoritesController.new);

class SearchHistoryController extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() =>
      ref.read(preferencesStoreProvider).loadSearchHistory();

  Future<void> add(String character) async {
    final settings = await ref.read(settingsControllerProvider.future);
    if (!settings.keepSearchHistory) return;
    final next = [
      character,
      for (final value in state.valueOrNull ?? const <String>[])
        if (value != character) value,
    ].take(100).toList(growable: false);
    state = AsyncData(next);
    await ref.read(preferencesStoreProvider).saveSearchHistory(next);
  }

  Future<void> clear() async {
    state = const AsyncData([]);
    await ref.read(preferencesStoreProvider).saveSearchHistory(const []);
  }
}

final searchHistoryControllerProvider =
    AsyncNotifierProvider<SearchHistoryController, List<String>>(
  SearchHistoryController.new,
);

final dailyContentProvider = FutureProvider<DailyContent?>((ref) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  final reroll = ref.watch(dailyRerollProvider);
  final items = await ref
      .read(dailyContentRepositoryProvider)
      .getByType(settings.dailyContentType);
  return ref
      .read(dailyContentServiceProvider)
      .select(items, DateTime.now(), settings.dailyContentType, reroll);
});

final todayCharacterProvider = FutureProvider<DailyContent?>((ref) async {
  final items = await ref
      .read(dailyContentRepositoryProvider)
      .getByType(DailyContentType.character);
  return ref
      .read(dailyContentServiceProvider)
      .select(items, DateTime.now(), DailyContentType.character, 0);
});

final todayCharactersProvider = FutureProvider<List<ChineseEntry>>((ref) async {
  final settings = await ref.watch(settingsControllerProvider.future);
  final entries = await ref.read(dictionaryRepositoryProvider).all();
  final pool = [
    for (final entry in entries)
      if (entry.pinyin.isNotEmpty &&
          entry.isVisibleFor(
            display: settings.scriptDisplay,
            maxLevel: settings.maxCharacterLevel,
          ))
        entry,
  ];
  if (pool.length <= 10) return pool;
  final now = DateTime.now();
  final random = Random(now.year * 10000 + now.month * 100 + now.day);
  final used = <int>{};
  final result = <ChineseEntry>[];
  while (result.length < 10) {
    final index = random.nextInt(pool.length);
    if (used.add(index)) result.add(pool[index]);
  }
  return result;
});

final cultureItemsProvider =
    FutureProvider.family<List<CultureItem>, CultureCategory>(
  (ref, category) =>
      ref.read(cultureRepositoryProvider).getByCategory(category),
);
