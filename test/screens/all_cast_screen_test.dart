import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/models/actor.dart';
import 'package:seriestime/screens/all_cast_screen.dart';

void main() {
  group('AllCastScreen - UI Components', () {
    testWidgets('shows AppBar with correct title', (tester) async {
      final actors = [
        Actor(name: 'John Doe', characterName: 'Character 1', profileUrl: null),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: AllCastScreen(fullCast: actors, seriesName: 'Test'),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Series Cast'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows GridView with correct configuration', (tester) async {
      final actors = [
        Actor(name: 'John Doe', characterName: 'Character 1', profileUrl: null),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: AllCastScreen(fullCast: actors, seriesName: 'Test'),
        ),
      );

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent;

      expect(delegate.maxCrossAxisExtent, equals(150));
      expect(delegate.childAspectRatio, equals(0.53));
      expect(gridView.padding, equals(const EdgeInsets.all(16)));
    });

    testWidgets('shows Scrollbar with controller', (tester) async {
      final actors = [
        Actor(name: 'John Doe', characterName: 'Character 1', profileUrl: null),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: AllCastScreen(fullCast: actors, seriesName: 'Test'),
        ),
      );

      final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
      expect(scrollbar.controller, isNotNull);
      expect(scrollbar.thumbVisibility, isTrue);
    });
  });

  group('AllCastScreen - Actor Display', () {
    testWidgets('displays single actor correctly', (tester) async {
      final actors = [
        Actor(name: 'John Doe', characterName: 'Character 1', profileUrl: null),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: AllCastScreen(fullCast: actors, seriesName: 'Test'),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Character 1'), findsOneWidget);
    });

    testWidgets('displays multiple actors', (tester) async {
      final actors = [
        Actor(name: 'John Doe', characterName: 'Character 1', profileUrl: null),
        Actor(
          name: 'Jane Smith',
          characterName: 'Character 2',
          profileUrl: null,
        ),
        Actor(
          name: 'Bob Johnson',
          characterName: 'Character 3',
          profileUrl: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: AllCastScreen(fullCast: actors, seriesName: 'Test'),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Bob Johnson'), findsOneWidget);
    });

    testWidgets('shows placeholder when profileUrl is null', (tester) async {
      final actors = [
        Actor(name: 'John Doe', characterName: 'Character 1', profileUrl: null),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: AllCastScreen(fullCast: actors, seriesName: 'Test'),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });

  group('AllCastScreen - Navigation', () {
    testWidgets('back button closes screen', (tester) async {
      final actors = [
        Actor(name: 'John Doe', characterName: 'Character 1', profileUrl: null),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AllCastScreen(fullCast: actors, seriesName: 'Test'),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Series Cast'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Series Cast'), findsNothing);
    });
  });

  group('AllCastScreen - Text Styling', () {
    testWidgets('verifies actor name styling', (tester) async {
      final actors = [
        Actor(name: 'John Doe', characterName: 'Character 1', profileUrl: null),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: AllCastScreen(fullCast: actors, seriesName: 'Test'),
        ),
      );

      final nameText = tester.widget<Text>(find.text('John Doe'));
      expect(nameText.style?.fontSize, equals(12));
      expect(nameText.style?.fontWeight, equals(FontWeight.bold));
      expect(nameText.maxLines, equals(1));
    });

    testWidgets('verifies character name styling', (tester) async {
      final actors = [
        Actor(name: 'John Doe', characterName: 'Character 1', profileUrl: null),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: AllCastScreen(fullCast: actors, seriesName: 'Test'),
        ),
      );

      final characterText = tester.widget<Text>(find.text('Character 1'));
      expect(characterText.style?.fontSize, equals(10));
      expect(characterText.maxLines, equals(4));
    });
  });

  group('AllCastScreen - Edge Cases', () {
    testWidgets('handles empty cast list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AllCastScreen(fullCast: [], seriesName: 'Test'),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('handles many actors', (tester) async {
      final actors = List.generate(
        30,
        (i) => Actor(
          name: 'Actor $i',
          characterName: 'Character $i',
          profileUrl: null,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AllCastScreen(fullCast: actors, seriesName: 'Test'),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Actor 0'), findsOneWidget);
    });
  });
}
