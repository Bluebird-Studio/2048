import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/game/game_2048.dart';

const emptyBoard = <List<int>>[
  [0, 0, 0, 0],
  [0, 0, 0, 0],
  [0, 0, 0, 0],
  [0, 0, 0, 0],
];

Game2048 gameWith(
  List<List<int>> board, {
  int score = 0,
  bool previouslyWon = false,
  TileSpawnPicker? spawnPicker,
}) =>
    Game2048.fromBoard(
      board,
      score: score,
      previouslyWon: previouslyWon,
      spawnPicker: spawnPicker ??
          (empty) => TileSpawn(empty.last, 2),
    );

void main() {
  group('new game and reset', () {
    test('new game spawns exactly two tiles and starts at zero score', () {
      final game = Game2048(
        spawnPicker: (empty) => TileSpawn(empty.first, 2),
      );
      expect(game.board[0], [2, 2, 0, 0]);
      expect(game.board.skip(1).expand((row) => row), everyElement(0));
      expect(game.score, 0);
      expect(game.hasWon, isFalse);
      expect(game.isGameOver, isFalse);
    });

    test('reset clears score and board and spawns two new tiles', () {
      final game = gameWith([
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      game.move(MoveDirection.left);
      expect(game.score, 4);
      game.reset();
      expect(game.score, 0);
      expect(game.board.expand((row) => row).where((v) => v != 0).length, 2);
    });
  });

  group('moves and merging', () {
    test('left compresses across gaps and merges once', () {
      final game = gameWith([
        [2, 0, 2, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      final result = game.move(MoveDirection.left);
      expect(result.changed, isTrue);
      expect(result.scoreGained, 4);
      expect(game.score, 4);
      expect(game.board[0], [4, 0, 0, 0]);
      expect(result.spawnedTile?.position, const TilePosition(3, 3));
      expect(game.board[3][3], 2);
    });

    test('four equal tiles become two pairs, never one chain merge', () {
      final game = gameWith([
        [2, 2, 2, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      final result = game.move(MoveDirection.left);
      expect(game.board[0], [4, 4, 0, 0]);
      expect(result.scoreGained, 8);
      expect(game.score, 8);
    });

    test('newly merged tile cannot merge again in the same move', () {
      final game = gameWith([
        [4, 4, 8, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      game.move(MoveDirection.left);
      expect(game.board[0], [8, 8, 0, 0]);
      expect(game.score, 8);
    });

    test('right moves toward the right edge', () {
      final game = gameWith([
        [2, 2, 2, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      game.move(MoveDirection.right);
      expect(game.board[0], [0, 0, 2, 4]);
      expect(game.score, 4);
    });

    test('up merges by columns', () {
      final game = gameWith([
        [2, 0, 0, 0],
        [2, 0, 0, 0],
        [4, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      game.move(MoveDirection.up);
      expect([for (final row in game.board) row[0]], [4, 4, 0, 0]);
      expect(game.score, 4);
    });

    test('down merges by columns from the bottom', () {
      final game = gameWith([
        [2, 0, 0, 0],
        [2, 0, 0, 0],
        [2, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      game.move(MoveDirection.down);
      expect([for (final row in game.board) row[0]], [0, 0, 2, 4]);
      expect(game.score, 4);
    });

    test('a no-op neither spawns nor increments score', () {
      var pickerCalls = 0;
      final game = gameWith([
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], score: 12, spawnPicker: (empty) {
        pickerCalls++;
        return TileSpawn(empty.first, 2);
      });
      final before = game.board;
      final result = game.move(MoveDirection.left);
      expect(result.changed, isFalse);
      expect(result.scoreGained, 0);
      expect(result.spawnedTile, isNull);
      expect(game.board, before);
      expect(game.score, 12);
      expect(pickerCalls, 0);
    });

    test('valid move spawns exactly one tile', () {
      var pickerCalls = 0;
      final game = gameWith([
        [0, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], spawnPicker: (empty) {
        pickerCalls++;
        return TileSpawn(empty.first, 4);
      });
      final result = game.move(MoveDirection.left);
      expect(pickerCalls, 1);
      expect(result.spawnedTile?.value, 4);
      expect(game.board[0], [2, 4, 0, 0]);
    });
  });

  group('win and loss', () {
    test('merging to 2048 wins and still permits further moves', () {
      final game = gameWith([
        [1024, 1024, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      final result = game.move(MoveDirection.left);
      expect(result.hasWon, isTrue);
      expect(game.hasWon, isTrue);
      expect(result.scoreGained, 2048);
      expect(game.isGameOver, isFalse);
      expect(game.move(MoveDirection.right).changed, isTrue);
    });

    test('a board with no empties and no adjacent matches is lost', () {
      final game = gameWith([
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
      ]);
      expect(game.isGameOver, isTrue);
      final before = game.board;
      expect(game.move(MoveDirection.left).changed, isFalse);
      expect(game.board, before);
    });

    test('a full board with adjacent equal values is not lost', () {
      final game = gameWith([
        [2, 2, 4, 8],
        [4, 8, 16, 32],
        [8, 16, 32, 64],
        [16, 32, 64, 128],
      ]);
      expect(game.isGameOver, isFalse);
      expect(game.move(MoveDirection.left).changed, isTrue);
    });

    test('win flag can be restored even after the winning tile merges', () {
      final game = gameWith([
        [4096, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], previouslyWon: true);
      expect(game.hasWon, isTrue);
    });
  });

  group('input validation and encapsulation', () {
    test('input board is copied and exposed board is immutable', () {
      final original = [
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ];
      final game = gameWith(original);
      final snapshot = game.board;
      original[0][0] = 128;
      expect(game.board[0][0], 2);
      expect(() => snapshot[0][0] = 4, throwsUnsupportedError);
      expect(() => snapshot.add([0, 0, 0, 0]), throwsUnsupportedError);
    });

    test('rejects invalid board dimensions, tile values and score', () {
      expect(() => gameWith([]), throwsArgumentError);
      expect(() => gameWith([
        [3, 0, 0, 0],
        ...emptyBoard.skip(1),
      ]), throwsArgumentError);
      expect(() => gameWith(emptyBoard, score: -1), throwsArgumentError);
    });

    test('rejects invalid injected spawn placements', () {
      final game = gameWith([
        [0, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], spawnPicker: (_) => const TileSpawn(TilePosition(0, 0), 8));
      expect(() => game.move(MoveDirection.left), throwsStateError);
    });
  });
}
