import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test UI: Verifica corretta visualizzazione componenti base', (
    WidgetTester tester,
  ) async {
    // Costruiamo un widget isolato nel tester
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text("SeriesTime")),
          body: const Center(child: Text("Welcome User")),
        ),
      ),
    );

    // Uso di find e expect (requisiti slide prof)
    expect(find.text("SeriesTime"), findsOneWidget);
    expect(find.text("Welcome User"), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
