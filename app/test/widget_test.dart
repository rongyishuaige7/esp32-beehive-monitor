import 'package:flutter_test/flutter_test.dart';

import 'package:beehive_monitor_app/main.dart';

void main() {
  testWidgets('App exposes a narrow local-response title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BeehiveMonitorApp());
    await tester.pumpAndSettle();
    expect(find.text('蜂箱传感器采样'), findsOneWidget);
    expect(find.text('未取得本次响应'), findsOneWidget);
  });
}
