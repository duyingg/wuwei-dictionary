import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuwei_dictionary/features/dictionary/stroke_order_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('笔顺解析只保留正式笔画形状', () async {
    final source = await rootBundle.loadString(
      'Aatime/makemeahanzi-master/svgs/39749.svg',
    );
    expect(parseStrokePaths(source), hasLength(14));
  });
}
