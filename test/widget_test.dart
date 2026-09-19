import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codeathone/main.dart';

void main() {
  testWidgets('App renders Sign In screen by default and logs in to Workbench', (WidgetTester tester) async {
    // Set desktop window surface size
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: GstBillingApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify Sign In screen renders with auto-filled credentials
    expect(find.textContaining('STAFF / ADMIN SIGN IN'), findsOneWidget);
    expect(find.textContaining('admin@apexdigital.in'), findsWidgets);

    // Tap SIGN IN button
    await tester.tap(find.text('SIGN IN TO WORKBENCH'));
    await tester.pumpAndSettle();

    // Verify Workbench renders
    expect(find.textContaining('Apex Digital'), findsWidgets);
    expect(find.textContaining('Dashboard'), findsWidgets);
  });
}
