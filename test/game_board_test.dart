import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/widgets/game_board.dart';

void main() {
  const initialTiles = <List<int>>[
    <int>[2, 0, 0, 0],
    <int>[0, 0, 0, 0],
    <int>[0, 0, 0, 0],
    <int>[0, 0, 0, 0],
  ];

  Widget board({ValueChanged<AxisDirection>? onDirection}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            height: 320,
            child: GameBoard(
              tiles: initialTiles,
              onDirection: onDirection,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('horizontal swipe reports its direction', (tester) async {
    final directions = <AxisDirection>[];
    await tester.pumpWidget(board(onDirection: directions.add));

    await tester.drag(find.byType(GameBoard), const Offset(100, 0));
    await tester.pump();

    expect(directions, <AxisDirection>[AxisDirection.right]);
  });

  testWidgets('vertical swipe reports its direction', (tester) async {
    final directions = <AxisDirection>[];
    await tester.pumpWidget(board(onDirection: directions.add));

    await tester.drag(find.byType(GameBoard), const Offset(0, -100));
    await tester.pump();

    expect(directions, <AxisDirection>[AxisDirection.up]);
  });

  testWidgets('short drag does not count as a move', (tester) async {
    final directions = <AxisDirection>[];
    await tester.pumpWidget(board(onDirection: directions.add));

    await tester.drag(find.byType(GameBoard), const Offset(10, 0));
    await tester.pump();

    expect(directions, isEmpty);
  });

  testWidgets('arrow keys report directions only on key down', (tester) async {
    final directions = <AxisDirection>[];
    await tester.pumpWidget(board(onDirection: directions.add));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);

    expect(
      directions,
      <AxisDirection>[AxisDirection.left, AxisDirection.up],
    );
  });

  testWidgets('all tiles have unique, position-aware accessibility labels',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(board());

    expect(find.bySemanticsLabel('2048 game board'), findsOneWidget);
    for (var row = 1; row <= 4; row++) {
      for (var column = 1; column <= 4; column++) {
        final label = row == 1 && column == 1
            ? 'Tile 2, row 1, column 1'
            : 'Empty tile, row $row, column $column';
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
    }
    semantics.dispose();
  });
}
