import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/widgets/common_widgets.dart';
import '../domain/models.dart';
import 'single_han_validator.dart';
import 'stroke_order_view.dart';

class CharacterDetailPage extends ConsumerStatefulWidget {
  const CharacterDetailPage({required this.value, super.key});
  final String value;

  @override
  ConsumerState<CharacterDetailPage> createState() =>
      _CharacterDetailPageState();
}

class _CharacterDetailPageState extends ConsumerState<CharacterDetailPage> {
  late final Future<ChineseEntry?> future;

  @override
  void initState() {
    super.initState();
    final valid = const SingleHanValidator().validate(widget.value) is ValidHan;
    future = valid
        ? ref
            .read(dictionaryRepositoryProvider)
            .findExactCharacter(widget.value)
        : Future.value(null);
    future.then((entry) {
      if (entry != null) {
        ref.read(searchHistoryControllerProvider.notifier).add(entry.character);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('汉字详情')),
      body: FutureBuilder<ChineseEntry?>(
        future: future,
        builder: (context, snapshot) {
          final entry = snapshot.data;
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (entry == null) {
            return const EmptyState(
                title: '未找到该字', message: '当前词库暂未收录，可以返回查询其他汉字。');
          }
          final favorites =
              ref.watch(favoritesControllerProvider).valueOrNull ?? {};
          final scriptRelations = _scriptRelationLabels(entry);
          return ResponsiveContent(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(entry.character,
                      style: const TextStyle(
                          fontSize: 88, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 24),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const SizedBox(height: 14),
                        Text(entry.pinyin.join(' · '),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary)),
                        const SizedBox(height: 12),
                        Text('部首 ${entry.radical}  ·  ${entry.strokeCount} 画'),
                        Text('${entry.structure}  ·  ${entry.unicode}',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (final label in scriptRelations)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(label),
                              ),
                            Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text('${entry.characterLevel} 级字'),
                            ),
                            if (entry.pinyin.length > 1)
                              const Chip(
                                visualDensity: VisualDensity.compact,
                                avatar: Icon(Icons.graphic_eq, size: 16),
                                label: Text('多音字'),
                              ),
                          ],
                        ),
                      ])),
                  IconButton(
                    tooltip:
                        favorites.contains(entry.character) ? '取消收藏' : '收藏',
                    onPressed: () => ref
                        .read(favoritesControllerProvider.notifier)
                        .toggle(entry.character),
                    icon: Icon(
                        favorites.contains(entry.character)
                            ? Icons.star
                            : Icons.star_border,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 30),
                  ),
                ]),
                const Divider(height: 36),
                if (entry.strokeOrderAsset != null) ...[
                  Row(
                    children: [
                      Text('笔顺', style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      Text(
                        '共 ${entry.strokeCount} 画',
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox.square(
                      dimension: 260,
                      child: StrokeOrderView(
                        assetPath: entry.strokeOrderAsset!,
                      ),
                    ),
                  ),
                  const Divider(height: 36),
                ],
                Text('释义', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (entry.senses.isEmpty)
                  Text(
                    '暂无释义，待后续补充。',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  )
                else
                  for (var i = 0; i < entry.senses.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (entry.senses[i].pinyin.isNotEmpty &&
                              (i == 0 ||
                                  entry.senses[i - 1].pinyin !=
                                      entry.senses[i].pinyin)) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                entry.senses[i].pinyin,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          Text(
                            '${i + 1}. '
                            '${entry.senses[i].partOfSpeech.isEmpty ? '' : '【${entry.senses[i].partOfSpeech}】'}'
                            '${entry.senses[i].definition}'
                            '${entry.senses[i].examples.isEmpty ? '' : '\n例：${entry.senses[i].examples.join('；')}'}',
                          ),
                        ],
                      ),
                    ),
                if (entry.decomposition != null &&
                    !entry.decomposition!.startsWith('？')) ...[
                  const Divider(height: 36),
                  Text('字形分解', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(entry.decomposition!),
                ],
                if (scriptRelations.any((label) => label != '简繁同形') ||
                    entry.variants.isNotEmpty) ...[
                  const Divider(height: 30),
                  Text('字形关系', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  for (final label in scriptRelations)
                    if (label != '简繁同形') Text(label),
                  if (entry.variants.isNotEmpty)
                    Text('异体字：${entry.variants.join('、')}'),
                ],
                const SizedBox(height: 30),
                Text('数据来源：${entry.sourceId}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

List<String> _scriptRelationLabels(ChineseEntry entry) {
  final simplified = entry.simplifiedForms
      .where((character) => character != entry.character)
      .toList();
  final traditional = entry.traditionalForms
      .where((character) => character != entry.character)
      .toList();
  if (simplified.isEmpty && traditional.isEmpty) return const ['简繁同形'];
  return [
    if (simplified.isNotEmpty) '简体字：${simplified.join('、')}',
    if (traditional.isNotEmpty) '繁体字：${traditional.join('、')}',
  ];
}
