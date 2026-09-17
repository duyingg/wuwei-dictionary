import '../domain/models.dart';

class DailyContentService {
  const DailyContentService();

  int stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  DailyContent? select(List<DailyContent> items, DateTime date,
      DailyContentType type, int offset) {
    if (items.isEmpty) return null;
    final localDay = DateTime(date.year, date.month, date.day)
        .difference(DateTime(2000))
        .inDays;
    final base = stableHash(type.name) + localDay;
    final index = (base + offset) % items.length;
    return items[index];
  }
}
