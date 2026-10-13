import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/game/game_2048.dart';

/// Independent reference implementation for exhaustive 4-cell line checks.
({List<int> tiles, int points}) referenceLine(List<int> line, bool reverse) {
  final compact = (reverse ? line.reversed : line).where((v) => v != 0).toList();
  final merged = <int>[];
  var points = 0;
  for (var i = 0; i < compact.length;) {
    if (i + 1 < compact.length && compact[i] == compact[i + 1]) {
      final value = compact[i] + compact[i + 1];
      merged.add(value);
      points += value;
      i += 2;
    } else {
      merged.add(compact[i++]);
    }
  }
  while (merged.length < 4) {
    merged.add(0);
  }
  return (tiles: reverse ? merged.reversed.toList() : merged, points: points);
}

void main() {
  group('exhaustive directional line invariants', () {
    const alphabet = [0, 2, 4, 8];
    for (final direction in MoveDirection.values) {
      test('256 lines for ${direction.name}', () {
        final vertical = direction == MoveDirection.up ||
            direction == MoveDirection.down;
        final reverse = direction == MoveDirection.right ||
            direction == MoveDirection.down;
        for (var code = 0; code < 256; code++) {
          var n = code;
          final line = List<int>.generate(4, (_) {
            final v = alphabet[n % 4];
            n ~/= 4;
            return v;
          });
          final board = List.generate(4, (_) => List.filled(4, 0));
          for (var i = 0; i < 4; i++) {
            if (vertical) {
              board[i][0] = line[i];
            } else {
              board[0][i] = line[i];
            }
          }
          final expected = referenceLine(line, reverse);
          final changed = expected.tiles.toString() != line.toString();
          final game = Game2048.fromBoard(
            board,
            spawnPicker: (empty) => TileSpawn(empty.last, 2),
          );
          final result = game.move(direction);
          final actual = game.board.map((row) => row.toList()).toList();
          if (result.spawnedTile case final spawn?) {
            expect(changed, isTrue);
            expect(actual[spawn.position.row][spawn.position.column], 2);
            actual[spawn.position.row][spawn.position.column] = 0;
          }
          final actualLine = [
            for (var i = 0; i < 4; i++)
              vertical ? actual[i][0] : actual[0][i],
          ];
          expect(actualLine, expected.tiles,
              reason: 'direction=${direction.name}, line=$line');
          expect(result.scoreGained, expected.points);
          expect(result.changed, changed);
          expect(result.spawnedTile == null, !changed);
          expect(game.score, expected.points);
        }
      });
    }
  });
}
