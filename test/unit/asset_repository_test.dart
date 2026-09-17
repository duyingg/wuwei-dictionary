import 'package:flutter_test/flutter_test.dart';
import 'package:wuwei_dictionary/features/data/repositories.dart';
import 'package:wuwei_dictionary/features/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('资源词库可解析并精确查询', () async {
    final repository = AssetDictionaryRepository();
    final entries = await repository.all();
    expect(entries.length, greaterThanOrEqualTo(20));
    final entry = await repository.findExactCharacter('澄');
    expect(entry?.pinyin, contains('chéng'));
  });

  test('五种索引均可返回模拟结果', () async {
    final repository = AssetDictionaryRepository();
    expect(await repository.findByPinyin('cheng'), isNotEmpty);
    expect(await repository.findByRadical('氵'), isNotEmpty);
    expect(await repository.findByStrokeCount(8), isNotEmpty);
    expect(await repository.findDifficultCharacters(), isNotEmpty);
    expect(await repository.findByRhyme('eng'), isNotEmpty);
  });

  test('多音字闯关资源包含100关并从主字典补入单', () async {
    final lessons = await PolyphonicLearningRepository().all();
    expect(lessons, hasLength(100));
    final single = lessons.singleWhere((lesson) => lesson.character == '单');
    expect(single.level, 58);
    expect(single.readings, orderedEquals(['dān', 'shàn', 'chán']));
    expect(single.phrases, orderedEquals(['单独', '单县', '单于']));
    expect(single.meanings.where((value) => value.isNotEmpty), hasLength(3));
  });

  test('文化资源包含完整节气、节日、诸子与百家姓读音', () async {
    final repository = AssetCultureRepository();
    final schools = await repository.getByCategory(CultureCategory.schools);
    expect(schools.map((e) => e.title), containsAll(['农家', '阴阳家', '兵家']));

    final other = await repository.getByCategory(CultureCategory.other);
    expect(other.map((e) => e.title),
        containsAll(['百家姓', '千字文', '三字经', '道德经', '二十四节气', '传统节日']));
    final surnames = await repository.getById('other-surnames');
    final surname = surnames!;
    expect(surname.readingContent, contains('赵(zhào)'));
    expect(surname.readingContent, contains('归海(guī hǎi)'));
    expect(surname.readingContent, contains('万俟(mò qí) 司马(sī mǎ)'));
    final lines = surname.content.split('\n');
    expect(lines, everyElement(hasLength(4)));
    expect(lines.length.isEven, isTrue);
    for (var index = 0; index < lines.length; index += 2) {
      expect('${lines[index]}${lines[index + 1]}', hasLength(8));
    }
    expect(lines.sublist(lines.length - 2), ['第五言福', '百家姓终']);

    final solar = await repository.getById('other-solar');
    expect(solar!.content.split('\n').where((e) => e.contains('|')),
        hasLength(24));
    expect(solar.content, contains('春雨惊春清谷天'));
    final festivals = await repository.getById('other-festival');
    expect(festivals!.content.split('\n').where((e) => e.contains('|')),
        hasLength(20));
  });

  test('诗词索引包含唐宋各两万及真实注释赏析', () async {
    final repository = AssetPoetryRepository();
    final items = await repository.all();
    expect(items.length, greaterThan(40000));
    expect(items.where((e) => e.dynasty == '唐').length,
        greaterThanOrEqualTo(20000));
    expect(items.where((e) => e.dynasty == '宋'), hasLength(20000));
    expect(items.any((e) => e.notes.isNotEmpty), isTrue);
    expect(items.any((e) => e.appreciation.isNotEmpty), isTrue);
    expect(
        items.map((e) => e.shuffleKey),
        orderedEquals(
          items.map((e) => e.shuffleKey).toList()..sort(),
        ));
    final sample = items.first;
    expect(
      sample.searchText,
      contains(sample.title.toLowerCase().replaceAll(RegExp(r'\s+'), '')),
    );
    expect(sample.searchText, contains(sample.author.toLowerCase()));
    expect(await repository.getById(sample.id), same(sample));
  });
}
