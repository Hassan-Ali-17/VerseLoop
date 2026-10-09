import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loopserve/app/app.dart';

void main() {
  testWidgets('LoopServeApp initializes and renders successfully', (WidgetTester tester) async {
    // Set wider surface size for responsive UI testing
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: LoopServeApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify main app title/text elements rendered
    expect(find.textContaining('EMBER'), findsWidgets);
  });
}
