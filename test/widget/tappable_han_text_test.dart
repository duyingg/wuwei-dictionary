import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wuwei_dictionary/core/widgets/tappable_han_text.dart';

void main() {
  testWidgets('文化正文汉字可进入详情且返回后保留原滚动位置', (tester) async {
    final controller = ScrollController();
    final router = GoRouter(
      initialLocation: '/culture/test',
      routes: [
        GoRoute(
          path: '/culture/test',
          builder: (_, __) => Scaffold(
            body: ListView(
              controller: controller,
              children: const [
                SizedBox(height: 700),
                TappableHanText('春风'),
                SizedBox(height: 700),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/character/:value',
          builder: (_, state) => Scaffold(
            body: Text('汉字详情：${state.pathParameters['value']}'),
          ),
        ),
      ],
    );
    addTearDown(() {
      controller.dispose();
      router.dispose();
    });

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    controller.jumpTo(650);
    await tester.pump();
    final before = controller.offset;

    await tester.tap(find.text('春'));
    await tester.pumpAndSettle();
    expect(find.text('汉字详情：春'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(controller.offset, before);
    expect(find.text('春'), findsOneWidget);
  });
}
