import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/game/game_2048.dart';
import 'package:game_2048/main.dart';
import 'package:game_2048/widgets/game_board.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Game2048 controlledGame(List<List<int>> board) => Game2048.fromBoard(
        board,
        spawnPicker: (empty) => TileSpawn(empty.last, 2),
      );

  testWidgets('swipe integrates tiles, score, persistence and restart',
      (tester) async {
    final game = controlledGame([
      [2, 2, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    await tester.pumpWidget(MaterialApp(home: GameScreen(initialGame: game)));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(GameBoard), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(game.board[0][0], 4);
    expect(game.score, 4);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('best_score'), 4);

    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();
    expect(game.score, 0);
    expect(preferences.getInt('best_score'), 4);
    expect(find.text('Best'), findsOneWidget);
  });

  testWidgets('best score reloads from local preferences', (tester) async {
    SharedPreferences.setMockInitialValues({'best_score': 256});
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(initialGame: controlledGame([
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ])),
    ));
    await tester.pumpAndSettle();
    expect(find.text('256'), findsOneWidget);
  });

  testWidgets('winning tile is communicated and play can continue',
      (tester) async {
    final game = controlledGame([
      [1024, 1024, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    await tester.pumpWidget(MaterialApp(home: GameScreen(initialGame: game)));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(GameBoard), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(game.hasWon, isTrue);
    expect(find.text('You reached 2048! Keep playing.'), findsOneWidget);
    expect(game.isGameOver, isFalse);
  });

  testWidgets('blocked board shows loss state and restart', (tester) async {
    final game = controlledGame([
      [2, 4, 2, 4],
      [4, 2, 4, 2],
      [2, 4, 2, 4],
      [4, 2, 4, 2],
    ]);
    await tester.pumpWidget(MaterialApp(home: GameScreen(initialGame: game)));
    await tester.pumpAndSettle();
    expect(find.text('No moves left. Start a new game.'), findsOneWidget);
    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();
    expect(game.isGameOver, isFalse);
  });
}
