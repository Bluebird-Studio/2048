import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/main.dart';

void main() {
  testWidgets('App displays the 2048 title', (tester) async {
    await tester.pumpWidget(const Game2048App());
    expect(find.textContaining('2048'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
