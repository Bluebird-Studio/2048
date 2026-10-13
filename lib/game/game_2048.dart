import 'dart:math';

/// The direction in which every tile is slid.
enum MoveDirection { up, down, left, right }

/// A zero-based position on the 4×4 board.
class TilePosition {
  const TilePosition(this.row, this.column);

  final int row;
  final int column;

  @override
  bool operator ==(Object other) =>
      other is TilePosition && row == other.row && column == other.column;

  @override
  int get hashCode => Object.hash(row, column);

  @override
  String toString() => 'TilePosition($row, $column)';
}

/// A tile to place after a valid move (or during a new game).
class TileSpawn {
  const TileSpawn(this.position, this.value);

  final TilePosition position;
  final int value;
}

/// Receives empty positions in row-major order and chooses the next tile.
///
/// Inject a picker in tests to avoid dependence on pseudo-random sequences.
typedef TileSpawnPicker = TileSpawn Function(List<TilePosition> emptyPositions);

/// The outcome of one requested move.
class MoveResult {
  const MoveResult({
    required this.changed,
    required this.scoreGained,
    required this.hasWon,
    required this.isGameOver,
    this.spawnedTile,
  });

  final bool changed;
  final int scoreGained;
  final bool hasWon;
  final bool isGameOver;
  final TileSpawn? spawnedTile;
}

/// Flutter-independent implementation of the standard 4×4 2048 rules.
///
/// The board is mutable only through [move] and [reset]. Reading [board]
/// returns a defensive, unmodifiable snapshot.
class Game2048 {
  Game2048({Random? random, TileSpawnPicker? spawnPicker})
      : _random = random ?? Random(),
        _spawnPicker = spawnPicker,
        _board = List.generate(boardSize, (_) => List.filled(boardSize, 0)) {
    _spawnTile();
    _spawnTile();
  }

  /// Restore a known board without creating additional tiles.
  Game2048.fromBoard(
    List<List<int>> board, {
    int score = 0,
    bool previouslyWon = false,
    Random? random,
    TileSpawnPicker? spawnPicker,
  })  : _random = random ?? Random(),
        _spawnPicker = spawnPicker,
        _board = _validatedCopy(board),
        _score = _validatedScore(score),
        _hasWon = previouslyWon {
    _updateStatus();
  }

  static const int boardSize = 4;
  static const int winningValue = 2048;

  final Random _random;
  final TileSpawnPicker? _spawnPicker;
  List<List<int>> _board;
  int _score = 0;
  bool _hasWon = false;
  bool _isGameOver = false;

  List<List<int>> get board => List.unmodifiable(
        _board.map((row) => List<int>.unmodifiable(row)),
      );

  int get score => _score;
  bool get hasWon => _hasWon;
  bool get isGameOver => _isGameOver;

  /// Start a new game with exactly two tiles and a score of zero.
  void reset() {
    _board = List.generate(boardSize, (_) => List.filled(boardSize, 0));
    _score = 0;
    _hasWon = false;
    _isGameOver = false;
    _spawnTile();
    _spawnTile();
  }

  /// Slide and merge tiles. No-op moves do not score or spawn a tile.
  ///
  /// Winning does not freeze play: the player may continue beyond 2048.
  MoveResult move(MoveDirection direction) {
    if (_isGameOver) {
      return _result(changed: false, scoreGained: 0);
    }

    final next = List.generate(
      boardSize,
      (row) => List<int>.from(_board[row]),
    );
    var gained = 0;
    var changed = false;

    for (var index = 0; index < boardSize; index++) {
      final positions = _linePositions(direction, index);
      final before = [for (final p in positions) _board[p.row][p.column]];
      final merged = _mergeLine(before);
      gained += merged.score;

      for (var offset = 0; offset < boardSize; offset++) {
        final p = positions[offset];
        next[p.row][p.column] = merged.values[offset];
        if (before[offset] != merged.values[offset]) {
          changed = true;
        }
      }
    }

    if (!changed) {
      return _result(changed: false, scoreGained: 0);
    }

    _board = next;
    _score += gained;
    final spawned = _spawnTile();
    _updateStatus();
    return _result(
      changed: true,
      scoreGained: gained,
      spawnedTile: spawned,
    );
  }

  MoveResult _result({
    required bool changed,
    required int scoreGained,
    TileSpawn? spawnedTile,
  }) =>
      MoveResult(
        changed: changed,
        scoreGained: scoreGained,
        hasWon: _hasWon,
        isGameOver: _isGameOver,
        spawnedTile: spawnedTile,
      );

  /// Positions ordered from the edge toward which tiles are moving.
  static List<TilePosition> _linePositions(
    MoveDirection direction,
    int index,
  ) {
    return [
      for (var offset = 0; offset < boardSize; offset++)
        switch (direction) {
          MoveDirection.left => TilePosition(index, offset),
          MoveDirection.right =>
            TilePosition(index, boardSize - 1 - offset),
          MoveDirection.up => TilePosition(offset, index),
          MoveDirection.down =>
            TilePosition(boardSize - 1 - offset, index),
        },
    ];
  }

  static _MergedLine _mergeLine(List<int> line) {
    final compact = line.where((value) => value != 0).toList();
    final result = <int>[];
    var score = 0;

    for (var i = 0; i < compact.length; i++) {
      if (i + 1 < compact.length && compact[i] == compact[i + 1]) {
        final value = compact[i] * 2;
        result.add(value);
        score += value;
        i++; // A merged tile cannot merge again in this move.
      } else {
        result.add(compact[i]);
      }
    }

    while (result.length < boardSize) {
      result.add(0);
    }
    return _MergedLine(result, score);
  }

  TileSpawn? _spawnTile() {
    final empty = <TilePosition>[
      for (var row = 0; row < boardSize; row++)
        for (var column = 0; column < boardSize; column++)
          if (_board[row][column] == 0) TilePosition(row, column),
    ];
    if (empty.isEmpty) return null;

    final TileSpawn spawn;
    if (_spawnPicker case final picker?) {
      spawn = picker(List<TilePosition>.unmodifiable(empty));
    } else {
      spawn = TileSpawn(
        empty[_random.nextInt(empty.length)],
        _random.nextInt(10) == 0 ? 4 : 2,
      );
    }

    if ((spawn.value != 2 && spawn.value != 4) ||
        !empty.contains(spawn.position)) {
      throw StateError('TileSpawnPicker must choose an empty cell and 2 or 4');
    }
    _board[spawn.position.row][spawn.position.column] = spawn.value;
    return spawn;
  }

  void _updateStatus() {
    _hasWon = _hasWon ||
        _board.any((row) => row.any((value) => value >= winningValue));

    if (_board.any((row) => row.contains(0))) {
      _isGameOver = false;
      return;
    }

    for (var row = 0; row < boardSize; row++) {
      for (var column = 0; column < boardSize; column++) {
        final value = _board[row][column];
        if ((row + 1 < boardSize &&
                _board[row + 1][column] == value) ||
            (column + 1 < boardSize &&
                _board[row][column + 1] == value)) {
          _isGameOver = false;
          return;
        }
      }
    }
    _isGameOver = true;
  }

  static int _validatedScore(int score) {
    if (score < 0) throw ArgumentError.value(score, 'score', 'Must be >= 0');
    return score;
  }

  static List<List<int>> _validatedCopy(List<List<int>> board) {
    if (board.length != boardSize ||
        board.any((row) => row.length != boardSize)) {
      throw ArgumentError.value(board, 'board', 'Expected a 4×4 board');
    }

    for (final row in board) {
      for (final value in row) {
        if (value < 0 ||
            (value != 0 && (value < 2 || (value & (value - 1)) != 0))) {
          throw ArgumentError.value(
            value,
            'board tile',
            'Tiles must be zero or powers of two >= 2',
          );
        }
      }
    }
    return [for (final row in board) List<int>.from(row)];
  }
}

class _MergedLine {
  const _MergedLine(this.values, this.score);

  final List<int> values;
  final int score;
}
