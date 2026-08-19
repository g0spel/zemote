import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zemote/state/log_store.dart';
import 'package:zemote/ui/log_page.dart';

void main() {
  // LogStore.instance is app-wide; keep tests self-contained by clearing.
  setUp(() => LogStore.instance.clear());
  tearDown(() => LogStore.instance.clear());

  Future<void> pump(WidgetTester tester, LogPage page) async {
    await tester.pumpWidget(MaterialApp(home: page));
    // Advance past the 250ms coalesced-flush window so the pending Timer
    // settles and the entries are visible.
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('diagnostics page shows only [诊断] entries', (tester) async {
    LogStore.instance.add('[诊断] 未知关闭码 4908');
    LogStore.instance.add('[v4] frame seq=12');
    LogStore.instance.add('[诊断] 快照解析失败');

    await pump(tester, const LogPage(diagnosticsOnly: true));

    expect(find.text('诊断日志'), findsOneWidget);
    expect(find.text('[诊断] 未知关闭码 4908'), findsOneWidget);
    expect(find.text('[诊断] 快照解析失败'), findsOneWidget);
    expect(find.text('[v4] frame seq=12'), findsNothing);
  });

  testWidgets('protocol log page excludes [诊断] entries', (tester) async {
    LogStore.instance.add('[诊断] 未知关闭码 4908');
    LogStore.instance.add('[v4] frame seq=12');

    await pump(tester, const LogPage());

    expect(find.text('协议日志'), findsOneWidget);
    expect(find.text('[v4] frame seq=12'), findsOneWidget);
    expect(find.text('[诊断] 未知关闭码 4908'), findsNothing);
    // Destructive clear lives only on the full log page.
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('clear action is not offered on the diagnostics page',
      (tester) async {
    LogStore.instance.add('[诊断] 未知关闭码 4908');
    await pump(tester, const LogPage(diagnosticsOnly: true));
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });
}
