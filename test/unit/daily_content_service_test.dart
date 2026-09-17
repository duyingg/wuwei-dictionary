import 'package:flutter_test/flutter_test.dart';
import 'package:wuwei_dictionary/features/data/repositories.dart';
import 'package:wuwei_dictionary/features/domain/models.dart';

void main() {
  const service = DailyContentService();
  final items = List.generate(
    4,
    (index) => DailyContent(
      id: '$index',
      type: DailyContentType.character,
      title: '$index',
      summary: 'summary',
      sourceId: 'app-original',
    ),
  );

  test('同日同类型选择稳定', () {
    final date = DateTime(2026, 8, 15, 9);
    expect(service.select(items, date, DailyContentType.character, 0)?.id,
        service.select(items, date, DailyContentType.character, 0)?.id);
  });

  test('次日和换一个均不会立即重复', () {
    final date = DateTime(2026, 8, 15);
    final today = service.select(items, date, DailyContentType.character, 0);
    final tomorrow = service.select(items, date.add(const Duration(days: 1)),
        DailyContentType.character, 0);
    final rerolled = service.select(items, date, DailyContentType.character, 1);
    expect(tomorrow?.id, isNot(today?.id));
    expect(rerolled?.id, isNot(today?.id));
  });

  test('空列表返回 null', () {
    expect(
        service.select([], DateTime(2026), DailyContentType.word, 0), isNull);
  });
}
