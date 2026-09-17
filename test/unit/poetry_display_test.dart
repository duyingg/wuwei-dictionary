import 'package:flutter_test/flutter_test.dart';
import 'package:wuwei_dictionary/features/culture/culture_pages.dart';

void main() {
  test('诗词源数据中的方框占位会明确标成原文缺字', () {
    expect(
      readablePoetrySource('上句。\n□□□□□□□，□□□□□□如。'),
      '上句。\n〔原文缺字〕，〔原文缺字〕如。',
    );
  });
}
