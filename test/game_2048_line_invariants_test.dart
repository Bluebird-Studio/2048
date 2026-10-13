import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/game/game_2048.dart';

/// An independent line-level reference for the 2048 merge rules.
({List<int> tiles, int points}) referenceMove(
  List<int> physicalLine,
  MoveDirection direction,
) {
  final reverse =
      direction == MoveDirection.right || direction == MoveDirection.down;
  final towardEdge =
      reverse ? physicalLine.reversed.toList() : List<int>.from(physicalLine);
  final nonzero = towardEdge.where((tile) => tile != 0).toList();
  final merged = <int>[];
  var points = 0;

  var index = 0;
  while (index < nonzero.length) {
    if (index + 1 < nonzero.length && nonzero[index] == nonzero[index + 1]) {
      final doubled = nonzero[index] + nonzero[index + 1];
      merged.add(doubled);
      points += doubled;
      index += 2;
    } else {
      merged.add(nonzero[index]);
      index++;
    }
  }

  while (merged.length < 4) {
    merged.add(0);
  }
  return (tiles: reverse ? merged.reversed.toList() : merged, points: points);
}

List<List<int>> boardForLine(List<int> line, MoveDirection direction) {
  final board = List.generate(4, (_) => List.filled(4, 0));
  for (var i = 0; i < 4; i++) {
    if (direction == MoveDirection.left || direction == MoveDirection.right) {
      board[0][i] = line[i];
    } else {
      board[i][0] = line[i];
    }
  }
  return board;
}

int sumTiles(List<List<int>> board) =>
    board.expand((row) => row).fold(0, (total, value) => total + value);

void main() {
  group('exhaustive 2048 line invariants', () {
    // 4^4 = 256 lines, each tested in all four directions.
    const alphabet = [0, 2, 4, 8];
    for (final direction in MoveDirection.values) {
      test('all 256 four-cell combinations: ${direction.name}', () {
        for (var encoded = 0; encoded < 256; encoded++) {
          var digits = encoded;
          final line = <int>[];
          for (var i = 0; i < 4; i++) {
            line.add(alphabet[digits % alphabet.length]);
            digits ~/= alphabet.length;
          }

          final initial = boardForLine(line, direction);
          final expected = referenceMove(line, direction);
          final expectedBoard = boardForLine(expected.tiles, direction);
          final changed = expectedBoard.toString() != initial.toString();
          final game = Game2048.fromBoard(
            initial,
            spawnPicker: (empty) => TileSpawn(empty.last, 2),
          );

          final outcome = game.move(direction);
          final context = 'direction=${direction.name}, input=$line';
          expect(outcome.changed, changed, reason: context);
          expect(outcome.scoreGained, expected.points, reason: context);
          expect(game.score, expected.points, reason: context);

          final observed = [
            for (final row in game.board) List<int>.from(row),
          ];
          if (changed) {
            final spawn = outcome.spawnedTile;
            expect(spawn, isNotNull, reason: context);
            expect(spawn!.value, 2, reason: context);
            expect(observed[spawn.position.row][spawn.position.column], 2,
                reason: context);
            observed[spawn.position.row][spawn.position.column] = 0;
          } else {
            expect(outcome.spawnedTile, isNull, reason: context);
          }

          expect(observed, expectedBoard, reason: context);
          expect(sumTiles(game.board),
              sumTiles(initial) + (changed ? 2 : 0),
              reason: context);
        }
      });
    }
  });
}
