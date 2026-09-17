import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/app_routes.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/tappable_han_text.dart';
import '../domain/models.dart';

class CulturePage extends ConsumerStatefulWidget {
  const CulturePage({super.key});
  @override
  ConsumerState<CulturePage> createState() => _CulturePageState();
}

class _CulturePageState extends ConsumerState<CulturePage> {
  var selected = CultureCategory.schools;
  var _sidebarVisible = true;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider).valueOrNull ??
        const AppSettings();
    return SafeArea(
      child: Column(children: [
        _CultureHeading(
          sidebarVisible: _sidebarVisible,
          onToggleSidebar: () =>
              setState(() => _sidebarVisible = !_sidebarVisible),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_sidebarVisible) ...[
                      SizedBox(
                        width: settings.sidebarWidth,
                        child: ListView(children: [
                          for (final category in CultureCategory.values)
                            _CategoryButton(
                              category: category,
                              selected: selected == category,
                              onTap: () => setState(() => selected = category),
                            ),
                        ]),
                      ),
                      const VerticalDivider(width: 1),
                    ],
                    Expanded(
                      child: selected == CultureCategory.tangPoems
                          ? const PoetryBrowser()
                          : _CultureGrid(category: selected),
                    ),
                  ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _CultureHeading extends StatelessWidget {
  const _CultureHeading({
    required this.sidebarVisible,
    required this.onToggleSidebar,
  });
  final bool sidebarVisible;
  final VoidCallback onToggleSidebar;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final title = Text('文化',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 5,
                  ));
          final toggle = HoverOnlyTooltipIconButton(
            message: sidebarVisible ? '隐藏侧边栏' : '显示侧边栏',
            icon: Icon(sidebarVisible
                ? Icons.keyboard_double_arrow_left
                : Icons.keyboard_double_arrow_right),
            onPressed: onToggleSidebar,
          );
          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: constraints.maxWidth < 520
                ? Row(
                    children: [
                      toggle,
                      Expanded(child: Center(child: title)),
                      const _CultureModeSelector(),
                    ],
                  )
                : Stack(alignment: Alignment.center, children: [
                    title,
                    Align(alignment: Alignment.centerLeft, child: toggle),
                    const Align(
                        alignment: Alignment.centerRight,
                        child: _CultureModeSelector()),
                  ]),
          );
        },
      );
}

class _CultureModeSelector extends ConsumerWidget {
  const _CultureModeSelector();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(cultureDisplayModeProvider);
    return SegmentedButton<CultureDisplayMode>(
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 7, vertical: 4)),
        textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
      ),
      showSelectedIcon: false,
      segments: [
        for (final value in CultureDisplayMode.values)
          ButtonSegment(value: value, label: Text(value.label)),
      ],
      selected: mode == null ? const {} : {mode},
      emptySelectionAllowed: true,
      onSelectionChanged: (value) {
        final next = value.firstOrNull;
        ref.read(cultureDisplayModeProvider.notifier).state = next;
      },
    );
  }
}

class _CultureGrid extends ConsumerWidget {
  const _CultureGrid({required this.category});
  final CultureCategory category;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cultureItemsProvider(category));
    return items.when(
      data: (values) => values.isEmpty
          ? const EmptyState(title: '暂无内容', message: '该分类暂未收录')
          : GridView.builder(
              key: PageStorageKey(category),
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.sizeOf(context).width >= 840 ? 2 : 1,
                mainAxisExtent: category == CultureCategory.schools ? 136 : 118,
                crossAxisSpacing: 14,
                mainAxisSpacing: 12,
              ),
              itemCount: values.length,
              itemBuilder: (_, index) => _CultureCard(item: values[index]),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const EmptyState(title: '加载失败', message: '请检查本地文化资源'),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton(
      {required this.category, required this.selected, required this.onTap});
  final CultureCategory category;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 20),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: .09)
              : Colors.transparent,
          border: Border(
              left: BorderSide(
            color: selected ? colors.primary : Colors.transparent,
            width: 3,
          )),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(category.label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? colors.primary : colors.onSurface,
              )),
        ),
      ),
    );
  }
}

class _CultureCard extends StatelessWidget {
  const _CultureCard({required this.item});
  final CultureItem item;
  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(AppRoutes.cultureDetail(item.id)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              if (item.category == CultureCategory.schools) ...[
                Container(
                  width: 66,
                  height: 90,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(item.title.substring(0, 1),
                      style: TextStyle(
                          fontSize: 30,
                          color: Theme.of(context).colorScheme.primary)),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 5),
                    Text(item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(height: 5),
                    Text(item.summary,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ]),
          ),
        ),
      );
}

enum _PoetrySort { ascending, descending, random }

extension on _PoetrySort {
  String get label => switch (this) {
        _PoetrySort.ascending => '正序',
        _PoetrySort.descending => '倒序',
        _PoetrySort.random => '乱序',
      };
}

class _PoetryFilters {
  const _PoetryFilters(
      {this.author = '',
      this.dynasty = '',
      this.form = '',
      this.style = '',
      this.theme = '',
      this.emotion = ''});
  final String author;
  final String dynasty;
  final String form;
  final String style;
  final String theme;
  final String emotion;
  int get activeCount => [author, dynasty, form, style, theme, emotion]
      .where((e) => e.isNotEmpty)
      .length;
}

class PoetryBrowser extends ConsumerStatefulWidget {
  const PoetryBrowser({super.key});
  @override
  ConsumerState<PoetryBrowser> createState() => _PoetryBrowserState();
}

class _PoetryBrowserState extends ConsumerState<PoetryBrowser> {
  static const _pageSize = 100;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  List<PoetryItem>? _random;
  List<PoetryItem>? _ascending;
  List<PoetryItem> _results = const [];
  var _visibleCount = _pageSize;
  var _sort = _PoetrySort.random;
  var _filters = const _PoetryFilters();
  var _query = '';
  var _loadedFullLibrary = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreAtHalfway);
    _loadLibrary(
      ref.read(settingsControllerProvider).valueOrNull?.fullPoetryLibrary ??
          false,
    );
  }

  void _loadLibrary(bool fullLibrary) {
    _loadedFullLibrary = fullLibrary;
    ref
        .read(poetryRepositoryProvider)
        .all(fullLibrary: fullLibrary)
        .then((items) {
      if (!mounted) return;
      _random = items;
      _ascending = List<PoetryItem>.of(items)
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_loadMoreAtHalfway)
      ..dispose();
    super.dispose();
  }

  void _loadMoreAtHalfway() {
    if (!_scrollController.hasClients || _visibleCount >= _results.length) {
      return;
    }
    final position = _scrollController.position;
    if (position.maxScrollExtent > 0 &&
        position.pixels >= position.maxScrollExtent * .5) {
      setState(() =>
          _visibleCount = math.min(_visibleCount + _pageSize, _results.length));
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      _query = value.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      _applyFilters();
    });
  }

  void _applyFilters() {
    final random = _random;
    final ascending = _ascending;
    if (!mounted || random == null || ascending == null) return;
    final Iterable<PoetryItem> source = switch (_sort) {
      _PoetrySort.random => random,
      _PoetrySort.ascending => ascending,
      _PoetrySort.descending => ascending.reversed,
    };
    final f = _filters;
    final next = <PoetryItem>[];
    for (final item in source) {
      if (_query.isNotEmpty && !item.searchText.contains(_query)) continue;
      if (f.author.isNotEmpty && !item.author.contains(f.author)) continue;
      if (f.dynasty.isNotEmpty && item.dynasty != f.dynasty) continue;
      if (f.form.isNotEmpty && item.form != f.form) continue;
      if (f.style.isNotEmpty && item.style != f.style) continue;
      if (f.theme.isNotEmpty && item.theme != f.theme) continue;
      if (f.emotion.isNotEmpty && item.emotion != f.emotion) continue;
      next.add(item);
    }
    setState(() {
      _results = next;
      _visibleCount = math.min(_pageSize, next.length);
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  Future<void> _showFilters() async {
    final result = await showModalBottomSheet<_PoetryFilters>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PoetryFilterSheet(initial: _filters),
    );
    if (result != null) {
      _filters = result;
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsControllerProvider, (_, next) {
      final fullLibrary = next.valueOrNull?.fullPoetryLibrary ?? false;
      if (fullLibrary != _loadedFullLibrary) {
        setState(() => _random = null);
        _loadLibrary(fullLibrary);
      }
    });
    if (_random == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final count = math.min(_visibleCount, _results.length);
    final search = TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: const InputDecoration(
          isDense: true,
          prefixIcon: Icon(Icons.search),
          hintText: '搜索作者、标题或诗句'),
    );
    final filter = OutlinedButton.icon(
      onPressed: _showFilters,
      icon: const Icon(Icons.tune, size: 18),
      label:
          Text(_filters.activeCount == 0 ? '筛选' : '筛选 ${_filters.activeCount}'),
    );
    final sort = PopupMenuButton<_PoetrySort>(
      tooltip: '排序',
      onSelected: (value) {
        _sort = value;
        _applyFilters();
      },
      itemBuilder: (_) => [
        for (final value in _PoetrySort.values)
          PopupMenuItem(value: value, child: Text(value.label))
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.swap_vert, size: 19),
          const SizedBox(width: 3),
          Text(_sort.label),
        ]),
      ),
    );
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return Column(children: [
              search,
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                filter,
                const SizedBox(width: 6),
                sort,
              ]),
            ]);
          }
          return Row(children: [
            Expanded(child: search),
            const SizedBox(width: 8),
            filter,
            const SizedBox(width: 6),
            sort,
          ]);
        }),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('共 ${_results.length} 首 · 已加载 $count 首',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      ),
      Expanded(
        child: _results.isEmpty
            ? const EmptyState(title: '没有找到诗词', message: '请减少筛选条件后再试')
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 5, 14, 20),
                itemCount: count,
                itemExtent: 126,
                itemBuilder: (_, index) => _PoetryCard(item: _results[index]),
              ),
      ),
    ]);
  }
}

class _PoetryCard extends StatelessWidget {
  const _PoetryCard({required this.item});
  final PoetryItem item;
  @override
  Widget build(BuildContext context) {
    final preview = item.content.replaceAll('\n', '　');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.poetryDetail(item.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium)),
                      Text('${item.dynasty} · ${item.author}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary)),
                    ]),
                    const SizedBox(height: 5),
                    Text(preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const Spacer(),
                    Wrap(spacing: 5, children: [
                      _TinyTag(item.form),
                      _TinyTag(item.style),
                      _TinyTag(item.theme),
                      _TinyTag(item.emotion),
                      if (item.notes.isNotEmpty) const _TinyTag('有注释'),
                      if (item.appreciation.isNotEmpty) const _TinyTag('有赏析'),
                    ]),
                  ]),
            ),
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ]),
        ),
      ),
    );
  }
}

class _TinyTag extends StatelessWidget {
  const _TinyTag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: const TextStyle(fontSize: 10)),
      );
}

class _PoetryFilterSheet extends StatefulWidget {
  const _PoetryFilterSheet({required this.initial});
  final _PoetryFilters initial;
  @override
  State<_PoetryFilterSheet> createState() => _PoetryFilterSheetState();
}

class _PoetryFilterSheetState extends State<_PoetryFilterSheet> {
  late final TextEditingController author;
  late String dynasty;
  late String form;
  late String style;
  late String theme;
  late String emotion;

  @override
  void initState() {
    super.initState();
    author = TextEditingController(text: widget.initial.author);
    dynasty = widget.initial.dynasty;
    form = widget.initial.form;
    style = widget.initial.style;
    theme = widget.initial.theme;
    emotion = widget.initial.emotion;
  }

  @override
  void dispose() {
    author.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('筛选诗词', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                  controller: author,
                  decoration: const InputDecoration(
                      labelText: '作者', hintText: '输入作者名')),
              const SizedBox(height: 12),
              Wrap(spacing: 12, runSpacing: 12, children: [
                _FilterDropdown(
                    '朝代',
                    dynasty,
                    const ['先秦', '汉', '唐', '五代', '宋', '元', '清'],
                    (v) => setState(() => dynasty = v)),
                _FilterDropdown(
                    '文体',
                    form,
                    const [
                      '词',
                      '曲',
                      '楚辞',
                      '五言绝句',
                      '七言绝句',
                      '五言律诗',
                      '七言律诗',
                      '乐府',
                      '古体诗'
                    ],
                    (v) => setState(() => form = v)),
                _FilterDropdown(
                    '风格',
                    style,
                    const ['豪放', '婉约', '雄浑', '清新', '冲淡', '其他'],
                    (v) => setState(() => style = v)),
                _FilterDropdown(
                    '主题',
                    theme,
                    const [
                      '山水田园',
                      '边塞',
                      '咏物',
                      '送别',
                      '怀古',
                      '思乡',
                      '节令',
                      '爱情闺怨',
                      '其他'
                    ],
                    (v) => setState(() => theme = v)),
                _FilterDropdown(
                    '感情',
                    emotion,
                    const ['思乡', '惜别', '忧国', '悲愁', '豪情', '闲适', '其他'],
                    (v) => setState(() => emotion = v)),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                TextButton(
                    onPressed: () =>
                        Navigator.pop(context, const _PoetryFilters()),
                    child: const Text('清空')),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(
                      context,
                      _PoetryFilters(
                        author: author.text.trim(),
                        dynasty: dynasty,
                        form: form,
                        style: style,
                        theme: theme,
                        emotion: emotion,
                      )),
                  child: const Text('应用筛选'),
                ),
              ]),
            ]),
          ),
        ),
      );
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown(this.label, this.value, this.values, this.onChanged);
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 160,
        child: DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(labelText: label, isDense: true),
          items: [
            const DropdownMenuItem(value: '', child: Text('全部')),
            for (final item in values)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: (value) => onChanged(value ?? ''),
        ),
      );
}

class CultureDetailPage extends ConsumerStatefulWidget {
  const CultureDetailPage({required this.id, super.key});
  final String id;

  @override
  ConsumerState<CultureDetailPage> createState() => _CultureDetailPageState();
}

class _CultureDetailPageState extends ConsumerState<CultureDetailPage> {
  late final Future<CultureItem?> _itemFuture;

  @override
  void initState() {
    super.initState();
    _itemFuture = ref.read(cultureRepositoryProvider).getById(widget.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('文化详情'),
          actions: const [
            Padding(
                padding: EdgeInsets.only(right: 12),
                child: _CultureModeSelector())
          ],
        ),
        body: FutureBuilder<CultureItem?>(
          future: _itemFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final item = snapshot.data;
            if (item == null) {
              return const EmptyState(title: '内容不存在', message: '请返回文化页重新选择');
            }
            return _CultureDetailBody(item: item);
          },
        ),
      );
}

class _CultureDetailBody extends ConsumerStatefulWidget {
  const _CultureDetailBody({required this.item});
  final CultureItem item;

  @override
  ConsumerState<_CultureDetailBody> createState() => _CultureDetailBodyState();
}

class _CultureDetailBodyState extends ConsumerState<_CultureDetailBody> {
  final _scrollController = ScrollController();
  final _viewportKey = GlobalKey();
  final _anchorKeys = <String, GlobalKey>{};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cultureDisplayModeProvider, (_, __) {
      final anchor = topVisibleHanAnchor(_anchorKeys, _viewportKey);
      if (anchor == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) restoreHanAnchor(_anchorKeys, anchor);
      });
    });
    final mode = ref.watch(cultureDisplayModeProvider);
    final item = widget.item;
    return ResponsiveContent(
      maxWidth: 800,
      child: ListView(
          key: _viewportKey,
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            TappableHanText(item.title,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            TappableHanText(item.subtitle,
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            const Divider(height: 36),
            if (item.content.trim().isEmpty)
              const SizedBox(
                  height: 300,
                  child: EmptyState(title: '暂未实装', message: '内容入口已预留，后续补充原文'))
            else if (mode != null && mode != CultureDisplayMode.reading)
              _UnavailableMode(mode: mode)
            else if (item.id == 'other-surnames' && item.readingContent != null)
              _SurnameReading(
                  content: item.readingContent!,
                  showPinyin: mode == CultureDisplayMode.reading,
                  anchorKeys: _anchorKeys)
            else if (item.id == 'other-festival')
              _FestivalTable(content: item.content, anchorKeys: _anchorKeys)
            else if (item.id == 'other-solar')
              _SolarTerms(content: item.content, anchorKeys: _anchorKeys)
            else if (mode == CultureDisplayMode.reading)
              _PinyinText(text: item.content, anchorKeys: _anchorKeys)
            else
              TappableHanText(item.content,
                  anchorKeys: _anchorKeys,
                  anchorPrefix: 'culture-body',
                  style: const TextStyle(height: 1.9, fontSize: 17)),
            const SizedBox(height: 30),
            Text('数据来源：${item.sourceId}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12)),
          ]),
    );
  }
}

class _UnavailableMode extends StatelessWidget {
  const _UnavailableMode({required this.mode});
  final CultureDisplayMode mode;
  @override
  Widget build(BuildContext context) => SizedBox(
      height: 300,
      child: EmptyState(title: '${mode.label}暂未实装', message: '目前仅开放“读音”模式'));
}

class _FestivalTable extends StatelessWidget {
  const _FestivalTable({required this.content, required this.anchorKeys});
  final String content;
  final Map<String, GlobalKey> anchorKeys;
  @override
  Widget build(BuildContext context) {
    final rows = content
        .split('\n')
        .where((line) => line.contains('|'))
        .map((line) => line.split('|'));
    return Column(children: [
      for (final row in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Expanded(
                child: TappableHanText(row.first,
                    anchorKeys: anchorKeys,
                    anchorPrefix: 'festival-${row.first}',
                    style: const TextStyle(fontSize: 17))),
            TappableHanText(row.last,
                anchorKeys: anchorKeys,
                anchorPrefix: 'festival-date-${row.first}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ),
    ]);
  }
}

class _SolarTerms extends StatelessWidget {
  const _SolarTerms({required this.content, required this.anchorKeys});
  final String content;
  final Map<String, GlobalKey> anchorKeys;
  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final rows = lines
        .where((line) => line.contains('|'))
        .map((e) => e.split('|'))
        .toList();
    final songStart = lines.indexWhere((e) => e.trim() == '节气歌');
    final song =
        songStart < 0 ? '' : lines.skip(songStart + 1).join('\n').trim();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LayoutBuilder(builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: constraints.maxWidth >= 600 ? 2.25 : 1.15,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
          ),
          itemBuilder: (context, index) {
            final row = rows[index];
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: .05),
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TappableHanText(row.first,
                    anchorKeys: anchorKeys,
                    anchorPrefix: 'solar-$index',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                FittedBox(
                  child: TappableHanText(row.last,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
              ]),
            );
          },
        );
      }),
      if (song.isNotEmpty) ...[
        const Divider(height: 36),
        TappableHanText('节气歌',
            anchorKeys: anchorKeys,
            anchorPrefix: 'solar-song-title',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TappableHanText(song,
            anchorKeys: anchorKeys,
            anchorPrefix: 'solar-song',
            style: const TextStyle(fontSize: 18, height: 2)),
      ],
    ]);
  }
}

class _SurnameReading extends StatelessWidget {
  const _SurnameReading(
      {required this.content,
      required this.showPinyin,
      required this.anchorKeys});
  final String content;
  final bool showPinyin;
  final Map<String, GlobalKey> anchorKeys;
  @override
  Widget build(BuildContext context) {
    final sentences = _parseSurnameSentences(content);
    return Column(children: [
      for (var start = 0; start < sentences.length; start += 2)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Expanded(
                child: _SurnameHalf(
                    entries: sentences[start],
                    showPinyin: showPinyin,
                    anchorKeys: anchorKeys,
                    anchorStart: start * 4)),
            Container(
                width: 1,
                height: showPinyin ? 46 : 30,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Theme.of(context).dividerColor),
            Expanded(
                child: _SurnameHalf(
                    entries: start + 1 < sentences.length
                        ? sentences[start + 1]
                        : const [],
                    showPinyin: showPinyin,
                    anchorKeys: anchorKeys,
                    anchorStart: (start + 1) * 4)),
          ]),
        ),
    ]);
  }
}

List<List<(String, String)>> _parseSurnameSentences(String content) {
  const terminalText = '百家姓终';
  const terminal = [
    ('百', 'bǎi'),
    ('家', 'jiā'),
    ('姓', 'xìng'),
    ('终', 'zhōng'),
  ];
  final entries = <(String, String)>[];
  final pattern = RegExp(r'([^\s()]+)\(([^)]+)\)');
  for (final line in content.split('\n')) {
    final lineEntries = pattern
        .allMatches(line)
        .map((match) => (match.group(1)!, match.group(2)!))
        .toList();
    if (lineEntries.map((entry) => entry.$1).join() == terminalText) {
      continue;
    }
    entries.addAll(lineEntries);
  }

  final sentences = <List<(String, String)>>[];
  var sentence = <(String, String)>[];
  var characterCount = 0;
  for (final entry in entries) {
    final entryLength = entry.$1.runes.length;
    if (characterCount + entryLength > 4) {
      throw const FormatException('百家姓分句超过四字');
    }
    sentence.add(entry);
    characterCount += entryLength;
    if (characterCount == 4) {
      sentences.add(sentence);
      sentence = <(String, String)>[];
      characterCount = 0;
    }
  }
  if (sentence.isNotEmpty) {
    throw const FormatException('百家姓分句不足四字');
  }
  sentences.add(terminal);
  if (sentences.length.isOdd) {
    throw const FormatException('百家姓必须每行两句、共八字');
  }
  return sentences;
}

class _SurnameHalf extends StatelessWidget {
  const _SurnameHalf(
      {required this.entries,
      required this.showPinyin,
      required this.anchorKeys,
      required this.anchorStart});
  final List<(String, String)> entries;
  final bool showPinyin;
  final Map<String, GlobalKey> anchorKeys;
  final int anchorStart;
  @override
  Widget build(BuildContext context) => Row(children: [
        for (var index = 0; index < entries.length; index++)
          Expanded(
            flex: entries[index].$1.runes.length,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (showPinyin)
                SizedBox(
                  height: 15,
                  child: FittedBox(
                    child: Text(entries[index].$2,
                        style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.primary)),
                  ),
                ),
              FittedBox(
                child: TappableHanText(entries[index].$1,
                    anchorKeys: anchorKeys,
                    anchorPrefix: 'surname',
                    anchorStart: anchorStart +
                        entries.take(index).fold(
                            0, (sum, entry) => sum + entry.$1.runes.length),
                    style: const TextStyle(fontSize: 21, letterSpacing: 0)),
              ),
            ]),
          ),
      ]);
}

class _PinyinText extends ConsumerWidget {
  const _PinyinText({required this.text, required this.anchorKeys});
  final String text;
  final Map<String, GlobalKey> anchorKeys;
  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder(
        future: ref.read(dictionaryRepositoryProvider).all(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final pinyin = {
            for (final entry in snapshot.data!)
              entry.character: entry.pinyin.isEmpty ? '' : entry.pinyin.first,
          };
          return Wrap(
              spacing: 1,
              runSpacing: 7,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                for (final indexed in text.characters.indexed)
                  if (indexed.$2 == '\n')
                    const SizedBox(width: double.infinity, height: 4)
                  else if (pinyin[indexed.$2]?.isNotEmpty ?? false)
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(pinyin[indexed.$2]!,
                          style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context).colorScheme.primary)),
                      TappableHanText(indexed.$2,
                          anchorKeys: anchorKeys,
                          anchorPrefix: 'culture-body',
                          anchorStart: indexed.$1,
                          style: const TextStyle(fontSize: 18)),
                    ])
                  else
                    TappableHanText(indexed.$2,
                        anchorKeys: anchorKeys,
                        anchorPrefix: 'culture-body',
                        anchorStart: indexed.$1,
                        style: const TextStyle(fontSize: 18, height: 1.8)),
              ]);
        },
      );
}

class PoetryDetailPage extends ConsumerStatefulWidget {
  const PoetryDetailPage({required this.id, super.key});
  final String id;

  @override
  ConsumerState<PoetryDetailPage> createState() => _PoetryDetailPageState();
}

class _PoetryDetailPageState extends ConsumerState<PoetryDetailPage> {
  Future<PoetryItem?>? _itemFuture;
  bool? _loadedFullLibrary;

  @override
  Widget build(BuildContext context) {
    final fullLibrary =
        ref.watch(settingsControllerProvider).valueOrNull?.fullPoetryLibrary ??
            false;
    if (_itemFuture == null || _loadedFullLibrary != fullLibrary) {
      _loadedFullLibrary = fullLibrary;
      _itemFuture = ref.read(poetryRepositoryProvider).getById(
            widget.id,
            fullLibrary: fullLibrary,
          );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('诗词'),
        actions: const [
          Padding(
              padding: EdgeInsets.only(right: 12),
              child: _CultureModeSelector())
        ],
      ),
      body: FutureBuilder<PoetryItem?>(
        future: _itemFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = snapshot.data;
          if (item == null) {
            return const EmptyState(title: '作品不存在', message: '请返回诗词列表重新选择');
          }
          return _PoetryDetailBody(item: item);
        },
      ),
    );
  }
}

class _PoetryDetailBody extends ConsumerStatefulWidget {
  const _PoetryDetailBody({required this.item});
  final PoetryItem item;

  @override
  ConsumerState<_PoetryDetailBody> createState() => _PoetryDetailBodyState();
}

class _PoetryDetailBodyState extends ConsumerState<_PoetryDetailBody> {
  final _scrollController = ScrollController();
  final _viewportKey = GlobalKey();
  final _anchorKeys = <String, GlobalKey>{};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cultureDisplayModeProvider, (_, __) {
      final anchor = topVisibleHanAnchor(_anchorKeys, _viewportKey);
      if (anchor == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) restoreHanAnchor(_anchorKeys, anchor);
      });
    });
    final item = widget.item;
    final displayContent = readablePoetrySource(item.content);
    final mode = ref.watch(cultureDisplayModeProvider);
    return ResponsiveContent(
      maxWidth: 760,
      child: ListView(
          key: _viewportKey,
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            TappableHanText(
              item.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            TappableHanText(
              '${item.dynasty} · ${item.author}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Center(
                child: Wrap(spacing: 6, children: [
              _TinyTag(item.form),
              _TinyTag(item.style),
              _TinyTag(item.theme),
              _TinyTag(item.emotion)
            ])),
            const Divider(height: 38),
            if (mode == CultureDisplayMode.reading)
              _PinyinText(text: displayContent, anchorKeys: _anchorKeys)
            else if (mode == CultureDisplayMode.notes)
              _PoetrySupplement(
                  title: '注释',
                  content: item.notes,
                  missing: '原始资源未提供注释',
                  anchorKeys: _anchorKeys,
                  anchorPrefix: 'culture-body')
            else if (mode == CultureDisplayMode.translation)
              _PoetrySupplement(
                  title: '翻译',
                  content: item.translation,
                  missing: '原始资源未提供翻译',
                  anchorKeys: _anchorKeys,
                  anchorPrefix: 'culture-body'),
            if (mode == null)
              TappableHanText(displayContent,
                  anchorKeys: _anchorKeys,
                  anchorPrefix: 'culture-body',
                  style: const TextStyle(fontSize: 18, height: 2)),
            if (item.appreciation.isNotEmpty) ...[
              const SizedBox(height: 24),
              _PoetrySupplement(
                title: '赏析',
                content: item.appreciation,
                missing: '',
                anchorKeys: _anchorKeys,
                anchorPrefix: 'poetry-appreciation',
              ),
            ],
            const SizedBox(height: 30),
            Text('数据来源：${item.sourceId}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12)),
          ]),
    );
  }
}

String readablePoetrySource(String content) =>
    content.replaceAll(RegExp('□+'), '〔原文缺字〕');

class _PoetrySupplement extends StatelessWidget {
  const _PoetrySupplement({
    required this.title,
    required this.content,
    required this.missing,
    required this.anchorKeys,
    required this.anchorPrefix,
  });
  final String title;
  final String content;
  final String missing;
  final Map<String, GlobalKey> anchorKeys;
  final String anchorPrefix;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TappableHanText(content.isEmpty ? missing : content,
                anchorKeys: anchorKeys,
                anchorPrefix: anchorPrefix,
                style: TextStyle(
                  height: 1.7,
                  color: content.isEmpty
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurface,
                )),
          ]),
        ),
      );
}
