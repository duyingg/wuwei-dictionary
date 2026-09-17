import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../core/language/pinyin_utils.dart';
import '../../core/widgets/common_widgets.dart';
import '../domain/character_visibility.dart';
import '../domain/models.dart';

class LearningPage extends StatelessWidget {
  const LearningPage({super.key});
  static const _items = [
    (
      '今日汉字',
      '每日随机学习十个汉字',
      Icons.calendar_month_outlined,
      AppRoutes.learningToday
    ),
    ('汉字收藏', '查看你收藏的汉字', Icons.star, AppRoutes.learningFavorites),
    ('猜汉字', '趣味猜字，增长知识', Icons.quiz_outlined, AppRoutes.learningGuess),
    ('造句', '用汉字造句练习', Icons.edit_outlined, AppRoutes.learningSentence),
    (
      '多音字学习',
      '闯关或无尽练习不同语境下的读音',
      Icons.route_outlined,
      AppRoutes.learningPolyphonic
    ),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ResponsiveContent(
          maxWidth: 760,
          child: Column(children: [
            const PageHeading('学习'),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) {
                  final item = _items[i];
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push(item.$4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 28),
                        child: Row(children: [
                          Icon(item.$3,
                              color: i.isEven
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.secondary,
                              size: 48),
                          const SizedBox(width: 28),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(item.$1,
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 6),
                                Text(item.$2,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant)),
                              ])),
                          Icon(Icons.chevron_right,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      );
}

class TodayCharacterPage extends ConsumerWidget {
  const TodayCharacterPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('今日汉字')),
        body: ref.watch(todayCharactersProvider).when(
              data: (items) => items.isEmpty
                  ? const EmptyState(title: '暂无内容', message: '本地资源为空')
                  : ResponsiveContent(
                      maxWidth: 900,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.sizeOf(context).width >= 720 ? 5 : 2,
                          childAspectRatio: .88,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => context
                                  .push(AppRoutes.character(item.character)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(item.pinyin.join(' · '),
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary)),
                                    const SizedBox(height: 5),
                                    Text(item.character,
                                        style: const TextStyle(fontSize: 54)),
                                    const SizedBox(height: 5),
                                    Text(
                                        '${item.strokeCount} 画 · ${item.radical}部',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const EmptyState(title: '加载失败', message: '请稍后重试'),
            ),
      );
}

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoritesControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('汉字收藏'),
        actions: [
          if (state.valueOrNull?.isNotEmpty ?? false)
            IconButton(
                tooltip: '清空收藏',
                onPressed: () => _confirmClear(context, ref),
                icon: const Icon(Icons.delete_outline))
        ],
      ),
      body: state.when(
        data: (items) => items.isEmpty
            ? const EmptyState(
                title: '还没有收藏',
                message: '在汉字详情页点击星标即可收藏',
                icon: Icons.star_border)
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  for (final value in items)
                    Card(
                        child: ListTile(
                            onTap: () =>
                                context.push(AppRoutes.character(value)),
                            leading: Text(value,
                                style: const TextStyle(fontSize: 36)),
                            title: const Text('查看汉字详情'),
                            trailing: IconButton(
                                onPressed: () => ref
                                    .read(favoritesControllerProvider.notifier)
                                    .toggle(value),
                                icon: Icon(Icons.star,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary))))
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(title: '读取失败', message: '无法读取本地收藏'),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text('清空收藏？'),
                content: const Text('此操作会移除全部收藏汉字。'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('清空'))
                ]));
    if (yes == true) {
      await ref.read(favoritesControllerProvider.notifier).clear();
    }
  }
}

class GuessCharacterPage extends ConsumerStatefulWidget {
  const GuessCharacterPage({super.key});
  @override
  ConsumerState<GuessCharacterPage> createState() => _GuessCharacterPageState();
}

class _GuessCharacterPageState extends ConsumerState<GuessCharacterPage> {
  static const _guessedKey = 'learning.guessed-characters.v1';
  late final Future<List<ChineseEntry>> _entriesFuture;
  final _random = Random();
  final _guessed = <String>{};
  ChineseEntry? _current;
  bool showHint = false;
  bool? correct;

  @override
  void initState() {
    super.initState();
    _entriesFuture = ref.read(dictionaryRepositoryProvider).all();
    _restoreProgress();
  }

  Future<void> _restoreProgress() async {
    final preferences = await SharedPreferences.getInstance();
    _guessed.addAll(preferences.getStringList(_guessedKey) ?? const []);
    if (mounted) setState(() => _current = null);
  }

  List<ChineseEntry> _pool(List<ChineseEntry> entries, AppSettings settings) {
    final seen = <String>{};
    return entries
        .where((entry) =>
            entry.isVisibleFor(
              display: settings.scriptDisplay,
              maxLevel: settings.maxCharacterLevel,
            ) &&
            entry.pinyin.isNotEmpty &&
            !entry.pinyin.any(PinyinUtils.isCompoundReading) &&
            seen.add(entry.character))
        .toList(growable: false);
  }

  void _pick(List<ChineseEntry> pool, {bool persistAnswer = false}) {
    if (persistAnswer && _current != null) {
      _guessed.add(_current!.character);
      SharedPreferences.getInstance().then(
        (value) => value.setStringList(_guessedKey, _guessed.toList()),
      );
    }
    var available = pool
        .where((entry) => !_guessed.contains(entry.character))
        .toList(growable: false);
    if (available.length > 1 && _current != null) {
      available = available
          .where((entry) => entry.character != _current!.character)
          .toList(growable: false);
    }
    setState(() {
      _current = available.isEmpty
          ? null
          : available[_random.nextInt(available.length)];
      showHint = false;
      correct = null;
    });
  }

  void _answer(bool isCorrect, List<ChineseEntry> pool) {
    setState(() => correct = isCorrect);
    if (isCorrect) {
      Future<void>.delayed(const Duration(milliseconds: 550), () {
        if (mounted) _pick(pool, persistAnswer: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('猜汉字'),
        ),
        body: FutureBuilder<List<ChineseEntry>>(
          future: _entriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const EmptyState(title: '加载失败', message: '无法读取本地字库');
            }
            final settings =
                ref.watch(settingsControllerProvider).valueOrNull ??
                    const AppSettings();
            final pool = _pool(snapshot.data ?? const [], settings);
            if (pool.isEmpty) {
              return const EmptyState(title: '暂无题目', message: '本地字库为空');
            }
            final available = pool
                .where((entry) => !_guessed.contains(entry.character))
                .toList(growable: false);
            _current ??= available.isEmpty
                ? null
                : available[_random.nextInt(available.length)];
            final entry = _current;
            if (entry == null) {
              return const EmptyState(
                title: '全部猜完了',
                message: '当前字库中的汉字已经全部猜出',
              );
            }
            return ResponsiveContent(
              maxWidth: 620,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(children: [
                        Row(children: [
                          Text('当前已猜出 ${_guessed.length} 字',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _pick(pool),
                            icon: const Icon(Icons.casino_outlined),
                            label: const Text('换一个'),
                          ),
                        ]),
                        Text('选择这个汉字的声母、韵母和声调',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                        Text(entry.character,
                            style: const TextStyle(fontSize: 100)),
                        _PinyinChoicePool(
                          key: ValueKey(entry.character),
                          acceptedReadings: entry.pinyin,
                          onAnswer: (value) => _answer(value, pool),
                        ),
                        const SizedBox(height: 20),
                        Row(children: [
                          OutlinedButton.icon(
                            onPressed: () =>
                                setState(() => showHint = !showHint),
                            icon: const Icon(Icons.lightbulb_outline),
                            label: Text(showHint ? '收起提示' : '提示'),
                          ),
                          const Spacer(),
                        ]),
                        if (showHint) ...[
                          const Divider(height: 30),
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('文字语义')),
                          if (entry.senses.isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(entry.senses
                                  .map((sense) => sense.definition)
                                  .join('\n')),
                            )
                          else
                            const SizedBox(height: 48),
                        ],
                        if (correct != null) ...[
                          const SizedBox(height: 18),
                          Text(correct! ? '回答正确' : '读音或声调不正确',
                              style: TextStyle(
                                  color: correct!
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}

class PolyphonicLearningPage extends ConsumerWidget {
  const PolyphonicLearningPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('多音字学习')),
        body: ResponsiveContent(
          maxWidth: 680,
          child: ListView(padding: const EdgeInsets.all(24), children: [
            Text(
              '选择学习方式',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '闯关使用已整理关卡；无尽模式会随进度扩充题库。',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            _PolyphonicModeCard(
              icon: Icons.route_outlined,
              title: '闯关',
              progress:
                  '当前第 ${min(ref.watch(polyphonicChallengeLevelProvider) + 1, 100)} 关',
              description: '按固定词组依次猜出每个字的全部读音。',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const _PolyphonicChallengePage(),
              )),
            ),
            const SizedBox(height: 16),
            _PolyphonicModeCard(
              icon: Icons.refresh,
              title: '无尽模式',
              progress:
                  '当前第 ${ref.watch(polyphonicEndlessCorrectProvider) ~/ 10 + 1} 轮',
              description: '随机练习；猜中十个后解锁一、二级扩展题库。',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const _PolyphonicEndlessPage(),
              )),
            ),
          ]),
        ),
      );
}

class _PolyphonicModeCard extends StatelessWidget {
  const _PolyphonicModeCard({
    required this.icon,
    required this.title,
    required this.progress,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String progress;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon,
                      color: Theme.of(context).colorScheme.primary, size: 29),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title,
                              style: Theme.of(context).textTheme.titleLarge),
                          const Spacer(),
                          Text(
                            progress,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        description,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      );
}

class _PinyinChoicePool extends StatefulWidget {
  const _PinyinChoicePool({
    super.key,
    required this.acceptedReadings,
    required this.onAnswer,
  });
  final List<String> acceptedReadings;
  final ValueChanged<bool> onAnswer;

  @override
  State<_PinyinChoicePool> createState() => _PinyinChoicePoolState();
}

class _PinyinChoicePoolState extends State<_PinyinChoicePool> {
  static const _finals = [
    'a',
    'o',
    'e',
    'ai',
    'ei',
    'ao',
    'ou',
    'an',
    'en',
    'ang',
    'eng',
    'ong',
    'i',
    'ia',
    'ie',
    'iao',
    'iu',
    'ian',
    'in',
    'iang',
    'ing',
    'iong',
    'u',
    'ua',
    'uo',
    'uai',
    'ui',
    'uan',
    'un',
    'uang',
    'ueng',
    'v',
    've',
    'van',
    'vn',
    'er'
  ];
  late final List<String> _initialPool;
  late final List<String> _finalPool;
  String? _initial;
  String? _final;
  int? _tone;

  @override
  void initState() {
    super.initState();
    final seed = widget.acceptedReadings.join('|').hashCode;
    final random = Random(seed);
    final correctInitials =
        widget.acceptedReadings.map(PinyinUtils.initialOf).toSet();
    final correctFinals =
        widget.acceptedReadings.map(PinyinUtils.finalOf).toSet();
    _initialPool = _buildPool(
      correctInitials,
      ['', ...PinyinUtils.initials],
      8,
      random,
    );
    _finalPool = _buildPool(correctFinals, _finals, 10, random);
  }

  static List<T> _buildPool<T>(
      Set<T> answers, List<T> source, int size, Random random) {
    final result = answers.toList();
    final candidates = source.where((item) => !answers.contains(item)).toList()
      ..shuffle(random);
    result.addAll(candidates.take(max(0, size - result.length)));
    return result..shuffle(random);
  }

  void _submit() {
    if (_initial == null || _final == null || _tone == null) return;
    final correct = widget.acceptedReadings.any((reading) =>
        PinyinUtils.initialOf(reading) == _initial &&
        PinyinUtils.finalOf(reading) == _final &&
        PinyinUtils.toneOf(reading) == _tone);
    widget.onAnswer(correct);
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        const Text('声母'),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final value in _initialPool)
            ChoiceChip(
              label: Text(value.isEmpty ? '零声母' : value),
              selected: _initial == value,
              onSelected: (_) => setState(() => _initial = value),
            ),
        ]),
        const SizedBox(height: 14),
        const Text('韵母'),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final value in _finalPool)
            ChoiceChip(
              label: Text(PinyinUtils.displayFinal(value)),
              selected: _final == value,
              onSelected: (_) => setState(() => _final = value),
            ),
        ]),
        const SizedBox(height: 14),
        const Text('声调'),
        const SizedBox(height: 6),
        Wrap(spacing: 7, children: [
          for (var tone = 1; tone <= 5; tone++)
            ChoiceChip(
              label: Text(tone == 5 ? '轻声' : '$tone 声'),
              selected: _tone == tone,
              onSelected: (_) => setState(() => _tone = tone),
            ),
        ]),
        const SizedBox(height: 18),
        FilledButton(onPressed: _submit, child: const Text('确认答案')),
      ]);
}

class _PolyphonicChallengePage extends ConsumerStatefulWidget {
  const _PolyphonicChallengePage();
  @override
  ConsumerState<_PolyphonicChallengePage> createState() =>
      _PolyphonicChallengePageState();
}

class _PolyphonicChallengePageState
    extends ConsumerState<_PolyphonicChallengePage> {
  late int _level;
  var _reading = 0;
  final _guessed = <String>[];
  bool? _correct;

  @override
  void initState() {
    super.initState();
    _level = ref.read(polyphonicChallengeLevelProvider);
  }

  Future<void> _answer(bool value, List<PolyphonicLesson> lessons) async {
    setState(() => _correct = value);
    if (!value) return;
    final lesson = lessons[_level];
    final currentReading = lesson.readings[_reading];
    final currentPhrase = lesson.phrases[_reading];
    final meaning =
        _reading < lesson.meanings.length ? lesson.meanings[_reading] : '';
    _guessed.add(lesson.readings[_reading]);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 42),
        title: const Text('本音达成'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(currentPhrase,
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('${lesson.character} · $currentReading',
              style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          const Divider(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              meaning.isEmpty ? '当前字典尚未收录该读音的释义。' : meaning,
              style: const TextStyle(height: 1.6),
            ),
          ),
        ]),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:
                Text(_reading + 1 < lesson.readings.length ? '下一个读音' : '下一关'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      _correct = null;
      if (_reading + 1 < lesson.readings.length) {
        _reading++;
      } else {
        _level++;
        ref.read(polyphonicChallengeLevelProvider.notifier).state = _level;
        _reading = 0;
        _guessed.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('多音字闯关')),
        body: ref.watch(polyphonicLessonsProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const EmptyState(title: '关卡加载失败', message: '无法读取多音字关卡文件'),
              data: (lessons) {
                if (_level >= lessons.length) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.emoji_events,
                          size: 72,
                          color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(height: 16),
                      const Text('已通关', style: TextStyle(fontSize: 30)),
                    ]),
                  );
                }
                final lesson = lessons[_level];
                return ResponsiveContent(
                  maxWidth: 620,
                  child: ListView(padding: const EdgeInsets.all(24), children: [
                    Row(children: [
                      Text('本关汉字：${lesson.character}',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Text('第 ${_level + 1} 关',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary)),
                      Text('  ·  共 ${lessons.length} 关',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ]),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(children: [
                          const Text('请选择词组中这个字的读音'),
                          const SizedBox(height: 18),
                          Text(lesson.phrases[_reading],
                              style: const TextStyle(
                                  fontSize: 48, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 22),
                          Wrap(spacing: 10, runSpacing: 10, children: [
                            for (var index = 0;
                                index < lesson.readings.length;
                                index++)
                              Container(
                                width: 88,
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(index < _guessed.length
                                    ? _guessed[index]
                                    : ''),
                              ),
                          ]),
                          const SizedBox(height: 24),
                          _PinyinChoicePool(
                            key: ValueKey('${lesson.level}-$_reading'),
                            acceptedReadings: [lesson.readings[_reading]],
                            onAnswer: (value) => _answer(value, lessons),
                          ),
                          if (_correct != null) ...[
                            const SizedBox(height: 14),
                            Text(_correct! ? '回答正确' : '当前词组的读音不正确',
                                style: TextStyle(
                                    color: _correct!
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.error)),
                          ],
                        ]),
                      ),
                    ),
                  ]),
                );
              },
            ),
      );
}

class _EndlessData {
  const _EndlessData(this.lessons, this.expanded);
  final List<PolyphonicLesson> lessons;
  final List<ChineseEntry> expanded;
}

class _PolyphonicEndlessPage extends ConsumerStatefulWidget {
  const _PolyphonicEndlessPage();
  @override
  ConsumerState<_PolyphonicEndlessPage> createState() =>
      _PolyphonicEndlessPageState();
}

class _PolyphonicEndlessPageState
    extends ConsumerState<_PolyphonicEndlessPage> {
  late final Future<_EndlessData> _dataFuture;
  final _random = Random();
  ChineseEntry? _current;
  var _correctCount = 0;
  bool? _correct;

  @override
  void initState() {
    super.initState();
    _correctCount = ref.read(polyphonicEndlessCorrectProvider);
    _dataFuture = _load();
  }

  Future<_EndlessData> _load() async {
    final settings = await ref.read(settingsControllerProvider.future);
    final lessons = await ref.read(polyphonicLearningRepositoryProvider).all();
    final entries = await ref.read(dictionaryRepositoryProvider).all();
    final seen = <String>{};
    final expanded = entries
        .where((entry) =>
            entry.isVisibleFor(
              display: settings.scriptDisplay,
              maxLevel: settings.maxCharacterLevel,
            ) &&
            !entry.difficult &&
            entry.pinyin.length > 1 &&
            !entry.pinyin.any(PinyinUtils.isCompoundReading) &&
            seen.add(entry.character))
        .toList(growable: false);
    return _EndlessData(lessons, expanded);
  }

  ChineseEntry _pick(_EndlessData data) {
    final pool = _correctCount < 10
        ? data.lessons
            .map((lesson) => ChineseEntry(
                  character: lesson.character,
                  pinyin: lesson.readings,
                  radical: '',
                  strokeCount: 0,
                  structure: '',
                  unicode: '',
                  senses: const [],
                  sourceId: '多音字闯关题库',
                ))
            .toList(growable: false)
        : data.expanded;
    if (pool.length == 1) return pool.first;
    ChineseEntry next;
    do {
      next = pool[_random.nextInt(pool.length)];
    } while (next.character == _current?.character);
    return next;
  }

  void _answer(bool value, _EndlessData data) {
    setState(() => _correct = value);
    if (!value) return;
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _correctCount++;
        ref.read(polyphonicEndlessCorrectProvider.notifier).state =
            _correctCount;
        _current = _pick(data);
        _correct = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('多音字无尽模式')),
        body: FutureBuilder<_EndlessData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return snapshot.hasError
                  ? const EmptyState(title: '加载失败', message: '无法读取多音字题库')
                  : const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            _current ??= _pick(data);
            final entry = _current!;
            return ResponsiveContent(
              maxWidth: 620,
              child: ListView(padding: const EdgeInsets.all(24), children: [
                Row(children: [
                  Text('第 ${_correctCount ~/ 10 + 1} 轮',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  Text('已猜中 $_correctCount 个'),
                ]),
                if (_correctCount < 10)
                  Text('再猜中若干字，将解锁一、二级扩展题库',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(children: [
                      const Text('这个多音字有哪些读音？'),
                      Text(entry.character,
                          style: const TextStyle(fontSize: 100)),
                      _PinyinChoicePool(
                        key: ValueKey(
                            '$entry-${entry.character}-$_correctCount'),
                        acceptedReadings: entry.pinyin,
                        onAnswer: (value) => _answer(value, data),
                      ),
                      if (_correct != null) ...[
                        const SizedBox(height: 14),
                        Text(_correct! ? '回答正确' : '读音不正确',
                            style: TextStyle(
                                color: _correct!
                                    ? Colors.green
                                    : Theme.of(context).colorScheme.error)),
                      ],
                    ]),
                  ),
                ),
              ]),
            );
          },
        ),
      );
}

class SentencePage extends StatefulWidget {
  const SentencePage({super.key});
  @override
  State<SentencePage> createState() => _SentencePageState();
}

class _SentencePageState extends State<SentencePage> {
  final controller = TextEditingController();
  String character = '春';
  String? saved;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('造句')),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          const Text('选择一个汉字', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          Wrap(spacing: 10, children: [
            for (final c in ['春', '明', '和', '学'])
              ChoiceChip(
                  label: Text(c),
                  selected: c == character,
                  onSelected: (_) => setState(() => character = c))
          ]),
          const SizedBox(height: 24),
          TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(hintText: '用“$character”写一句话')),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() => saved = controller.text.trim());
                }
              },
              child: const Text('保存练习')),
          if (saved != null) ...[
            const SizedBox(height: 24),
            Card(
                child: ListTile(
                    leading: const Icon(Icons.check_circle_outline,
                        color: Colors.green),
                    title: const Text('本次练习'),
                    subtitle: Text(saved!)))
          ],
        ]),
      );
}
