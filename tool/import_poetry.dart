import 'dart:convert';
import 'dart:io';

const _root = 'Aatime/chinese-poetry-master';
const _quotaTang = 20000;
const _quotaSong = 20000;

void main() {
  final root = Directory(_root);
  if (!root.existsSync()) {
    stderr.writeln('未找到 chinese-poetry-master。');
    exitCode = 1;
    return;
  }

  final tang = <_RawPoem>[];
  final song = <_RawPoem>[];
  final other = <_RawPoem>[];
  final seen = <String>{};
  var sequence = 0;

  void add(Map<String, dynamic> json, String dynasty, String baseForm,
      List<_RawPoem> target,
      {bool curated = false}) {
    final rawParagraphs = json['paragraphs'] ?? json['content'] ?? json['para'];
    final paragraphs = rawParagraphs is List
        ? List<String>.from(rawParagraphs)
            .where((line) => line.trim().isNotEmpty)
            .toList()
        : const <String>[];
    if (paragraphs.isEmpty) return;
    final title = (json['title'] ?? json['rhythmic'] ?? '无题').toString().trim();
    final author = (json['author'] ?? '佚名').toString().trim();
    final content = paragraphs.join('\n');
    final key = '$dynasty|$author|$title|$content';
    if (!seen.add(key)) return;
    final tags = List<String>.from(json['tags'] as List? ?? const []);
    final notes = _textOf(json['notes']);
    final translation = _firstText(json, const [
      'translation',
      'translations',
      'translated',
      'vernacular',
    ]);
    final appreciation = _firstText(json, const [
      'appreciation',
      'analysis',
      'prologue',
      'comment',
    ]);
    target.add(_RawPoem(
      title: title,
      author: author,
      dynasty: dynasty,
      form: _formOf(baseForm, paragraphs, tags),
      style: _styleOf(title, content, tags),
      theme: _themeOf(title, content, tags),
      emotion: _emotionOf(title, content, tags),
      content: content,
      notes: notes,
      translation: translation,
      appreciation: appreciation,
      sequence: sequence++,
      curated: curated,
    ));
  }

  void readFile(String path, String dynasty, String form, List<_RawPoem> target,
      {bool curated = false}) {
    final file = File(path);
    if (!file.existsSync()) return;
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! List) return;
    for (final value in decoded) {
      if (value is Map) {
        add(Map<String, dynamic>.from(value), dynasty, form, target,
            curated: curated);
      }
    }
  }

  readFile('$_root/全唐诗/唐诗三百首.json', '唐', '诗', tang, curated: true);
  readFile('$_root/宋词/宋词三百首.json', '宋', '词', song, curated: true);

  final tangFiles = Directory('$_root/全唐诗')
      .listSync()
      .whereType<File>()
      .where((file) => RegExp(r'poet\.tang\.\d+\.json$').hasMatch(file.path))
      .toList()
    ..sort((a, b) => _fileNumber(a.path).compareTo(_fileNumber(b.path)));
  for (final file in tangFiles) {
    readFile(file.path, '唐', '诗', tang);
  }

  final songFiles = Directory('$_root/宋词')
      .listSync()
      .whereType<File>()
      .where((file) => RegExp(r'ci\.song\.\d+\.json$').hasMatch(file.path))
      .toList()
    ..sort((a, b) => _fileNumber(a.path).compareTo(_fileNumber(b.path)));
  for (final file in songFiles) {
    readFile(file.path, '宋', '词', song);
  }
  final songPoemFiles = Directory('$_root/全唐诗')
      .listSync()
      .whereType<File>()
      .where((file) => RegExp(r'poet\.song\.\d+\.json$').hasMatch(file.path))
      .toList()
    ..sort((a, b) => _fileNumber(a.path).compareTo(_fileNumber(b.path)));
  for (final file in songPoemFiles) {
    readFile(file.path, '宋', '诗', song);
  }

  readFile('$_root/元曲/yuanqu.json', '元', '曲', other);
  readFile('$_root/诗经/shijing.json', '先秦', '诗', other);
  readFile('$_root/楚辞/chuci.json', '先秦', '楚辞', other);
  readFile('$_root/曹操诗集/caocao.json', '汉', '诗', other);
  readFile('$_root/水墨唐诗/shuimotangshi.json', '唐', '诗', other);
  final otherDirectories = [
    ('$_root/五代诗词', '五代', '词'),
    ('$_root/纳兰性德', '清', '词'),
  ];
  for (final source in otherDirectories) {
    final files = Directory(source.$1)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'));
    for (final file in files) {
      readFile(file.path, source.$2, source.$3, other);
    }
  }

  final selected = <_RawPoem>[
    ..._takeStable(tang, _quotaTang),
    ..._takeStable(song, _quotaSong),
    ...other,
  ];
  final full = <_RawPoem>[...tang, ...song, ...other];
  final outFile = _writeOutput('assets/data/poetry_items.json', selected);
  final fullFile = _writeOutput('assets/data/poetry_items_full.json', full);
  _writeReport(tang, song, other, selected, full, outFile, fullFile);

  stdout.writeln(
    '诗词候选：唐 ${tang.length}，宋诗词 ${song.length}，其他 ${other.length}',
  );
  stdout.writeln(
    '默认 ${selected.length} 条（${outFile.lengthSync()} 字节），'
    '全量 ${full.length} 条（${fullFile.lengthSync()} 字节）。',
  );
}

void _writeReport(
  List<_RawPoem> tang,
  List<_RawPoem> song,
  List<_RawPoem> other,
  List<_RawPoem> selected,
  List<_RawPoem> full,
  File defaultFile,
  File fullFile,
) {
  int withNotes(Iterable<_RawPoem> values) =>
      values.where((item) => item.notes.isNotEmpty).length;
  int withTranslations(Iterable<_RawPoem> values) =>
      values.where((item) => item.translation.isNotEmpty).length;
  int withAppreciations(Iterable<_RawPoem> values) =>
      values.where((item) => item.appreciation.isNotEmpty).length;
  final buffer = StringBuffer()
    ..writeln('# 诗词资源导入报告')
    ..writeln()
    ..writeln('- 唐诗候选：${tang.length} 首')
    ..writeln('- 宋诗词候选：${song.length} 首')
    ..writeln('- 其他诗词：${other.length} 首（全部进入默认库）')
    ..writeln('- 默认库：${selected.length} 首，${defaultFile.lengthSync()} 字节')
    ..writeln('- 全量库：${full.length} 首，${fullFile.lengthSync()} 字节')
    ..writeln()
    ..writeln('| 范围 | 有注释 | 有翻译 | 有赏析/解说 |')
    ..writeln('|---|---:|---:|---:|')
    ..writeln('| 默认库 | ${withNotes(selected)} | '
        '${withTranslations(selected)} | ${withAppreciations(selected)} |')
    ..writeln('| 全量库 | ${withNotes(full)} | '
        '${withTranslations(full)} | ${withAppreciations(full)} |')
    ..writeln()
    ..writeln('扩展内容只读取源文件真实字段：`notes` 作为注释，翻译相关字段作为翻译，'
        '`appreciation`、`analysis`、`prologue`、`comment` 作为赏析或解说。');
  File('项目文档/诗词资源导入报告.md').writeAsStringSync('$buffer');
}

File _writeOutput(String path, List<_RawPoem> poems) {
  final output = [
    for (final poem in poems) poem.toJson()
  ]..sort((a, b) => (a['shuffleKey'] as int).compareTo(b['shuffleKey'] as int));
  return File(path)..writeAsStringSync(jsonEncode(output));
}

String _textOf(Object? value) {
  if (value is String) return value.trim();
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .join('\n');
  }
  return '';
}

String _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _textOf(json[key]);
    if (value.isNotEmpty) return value;
  }
  return '';
}

List<_RawPoem> _takeStable(List<_RawPoem> source, int quota) {
  bool isPriority(_RawPoem poem) =>
      poem.curated ||
      poem.notes.isNotEmpty ||
      poem.translation.isNotEmpty ||
      poem.appreciation.isNotEmpty;
  final curated = source.where(isPriority).toList();
  final rest = source.where((poem) => !isPriority(poem)).toList()
    ..sort((a, b) => a.shuffleKey.compareTo(b.shuffleKey));
  return [...curated, ...rest].take(quota).toList();
}

int _fileNumber(String path) =>
    int.tryParse(RegExp(r'\.(\d+)\.json$').firstMatch(path)?.group(1) ?? '') ??
    0;

String _formOf(String base, List<String> lines, List<String> tags) {
  for (final value in const [
    '五言绝句',
    '七言绝句',
    '五言律诗',
    '七言律诗',
    '乐府',
  ]) {
    if (tags.any((tag) => tag.contains(value))) return value;
  }
  if (base != '诗') return base;
  final lengths = lines.map(_hanLength).toSet();
  if (lengths.length == 1) {
    final length = lengths.first;
    if (lines.length == 4 && length == 5) return '五言绝句';
    if (lines.length == 4 && length == 7) return '七言绝句';
    if (lines.length == 8 && length == 5) return '五言律诗';
    if (lines.length == 8 && length == 7) return '七言律诗';
  }
  return '古体诗';
}

int _hanLength(String value) =>
    value.runes.where((rune) => rune >= 0x3400 && rune <= 0x9fff).length;

String _styleOf(String title, String content, List<String> tags) {
  final text = '$title$content${tags.join()}';
  if (_has(text, ['豪放', '铁马', '沙场', '壮志', '长风'])) return '豪放';
  if (_has(text, ['婉约', '闺', '红楼', '柔情'])) return '婉约';
  if (_has(text, ['边塞', '羌笛', '烽火', '戍边'])) return '雄浑';
  if (_has(text, ['田园', '桑麻', '柴门', '归隐'])) return '清新';
  if (_has(text, ['幽', '空山', '禅', '孤云'])) return '冲淡';
  return '其他';
}

String _themeOf(String title, String content, List<String> tags) {
  final text = '$title$content${tags.join()}';
  if (_has(text, ['送', '别', '留别', '赠'])) return '送别';
  if (_has(text, ['思乡', '归乡', '故乡', '客愁'])) return '思乡';
  if (_has(text, ['边塞', '出塞', '从军', '戍', '胡马'])) return '边塞';
  if (_has(text, ['怀古', '古迹', '赤壁', '金陵'])) return '怀古';
  if (_has(text, ['咏物', '咏梅', '咏竹', '咏蝉'])) return '咏物';
  if (_has(text, ['田园', '田家', '山水', '溪', '山居'])) return '山水田园';
  if (_has(text, ['七夕', '中秋', '重阳', '清明', '元宵'])) return '节令';
  if (_has(text, ['闺', '相思', '鸳鸯', '红豆'])) return '爱情闺怨';
  return '其他';
}

String _emotionOf(String title, String content, List<String> tags) {
  final text = '$title$content${tags.join()}';
  if (_has(text, ['思乡', '故乡', '归心', '独客'])) return '思乡';
  if (_has(text, ['送别', '离别', '别君', '柳色'])) return '惜别';
  if (_has(text, ['忧国', '国破', '黎民', '征夫'])) return '忧国';
  if (_has(text, ['相思', '愁', '泪', '断肠', '寂寞'])) return '悲愁';
  if (_has(text, ['壮志', '豪情', '仗剑', '长风'])) return '豪情';
  if (_has(text, ['闲', '醉', '归隐', '山居'])) return '闲适';
  return '其他';
}

bool _has(String text, List<String> values) => values.any(text.contains);

int _stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

class _RawPoem {
  _RawPoem({
    required this.title,
    required this.author,
    required this.dynasty,
    required this.form,
    required this.style,
    required this.theme,
    required this.emotion,
    required this.content,
    required this.notes,
    required this.translation,
    required this.appreciation,
    required this.sequence,
    required this.curated,
  });

  final String title;
  final String author;
  final String dynasty;
  final String form;
  final String style;
  final String theme;
  final String emotion;
  final String content;
  final String notes;
  final String translation;
  final String appreciation;
  final int sequence;
  final bool curated;

  int get shuffleKey => _stableHash('$dynasty|$author|$title|$content');

  Map<String, dynamic> toJson() => {
        'id': 'poetry-${shuffleKey.toRadixString(16)}-$sequence',
        'title': title,
        'author': author,
        'dynasty': dynasty,
        'form': form,
        'style': style,
        'theme': theme,
        'emotion': emotion,
        'content': content,
        if (notes.isNotEmpty) 'notes': notes,
        if (translation.isNotEmpty) 'translation': translation,
        if (appreciation.isNotEmpty) 'appreciation': appreciation,
        'sequence': sequence,
        'shuffleKey': shuffleKey,
        'searchText': '$title$author$content'.toLowerCase().replaceAll(
              RegExp(r'\s+'),
              '',
            ),
        'sourceId': 'chinese-poetry',
      };
}
