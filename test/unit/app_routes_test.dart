import 'package:flutter_test/flutter_test.dart';
import 'package:wuwei_dictionary/app/app_routes.dart';

void main() {
  test('动态路由参数会进行 URI 编码', () {
    expect(AppRoutes.character('𠮷'), '/character/%F0%A0%AE%B7');
    expect(
        AppRoutes.cultureDetail('id/with space'), '/culture/id%2Fwith%20space');
  });

  test('路由模式与固定入口保持稳定', () {
    expect(AppRoutes.characterPattern, '/character/:value');
    expect(AppRoutes.indexPattern, '/index/:type');
    expect(AppRoutes.settingsGeneral, '/settings/general');
  });
}
