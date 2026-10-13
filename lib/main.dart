import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/game_2048.dart';
import 'widgets/game_board.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Game2048App());
}

class Game2048App extends StatelessWidget {
  const Game2048App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9A8172)),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

/// Single source of truth: [Game2048] owns all board and scoring rules.
/// Supplying a game allows deterministic widget tests.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.initialGame});

  final Game2048? initialGame;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const _bestScoreKey = 'best_score';

  late final Game2048 _game;
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _game = widget.initialGame ?? Game2048();
    _bestScore = _game.score;
    unawaited(_loadBestScore());
  }

  Future<void> _loadBestScore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _bestScore = math.max(
          _bestScore,
          preferences.getInt(_bestScoreKey) ?? 0,
        );
      });
    } on Exception {
      // Persistence is optional: the game remains playable offline.
    }
  }

  Future<void> _saveBestScore(int score) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getInt(_bestScoreKey) ?? 0;
      if (score > stored) {
        await preferences.setInt(_bestScoreKey, score);
      }
    } on Exception {
      // A storage failure must not prevent moving tiles.
    }
  }

  MoveDirection _direction(AxisDirection direction) => switch (direction) {
        AxisDirection.up => MoveDirection.up,
        AxisDirection.down => MoveDirection.down,
        AxisDirection.left => MoveDirection.left,
        AxisDirection.right => MoveDirection.right,
      };

  void _move(AxisDirection direction) {
    final result = _game.move(_direction(direction));
    if (!result.changed) return;

    if (_game.score > _bestScore) {
      _bestScore = _game.score;
      unawaited(_saveBestScore(_bestScore));
    }
    setState(() {});
  }

  void _restart() {
    setState(_game.reset);
  }

  Widget _stat(String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text('$value', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardSize = math.min(440.0, MediaQuery.sizeOf(context).width - 32);
    final message = _game.isGameOver
        ? 'No moves left. Start a new game.'
        : _game.hasWon
            ? 'You reached 2048! Keep playing.'
            : 'Join equal tiles to reach the goal.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('2048'),
        actions: [
          TextButton.icon(
            onPressed: _restart,
            icon: const Icon(Icons.refresh),
            label: const Text('New game'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _stat('Score', _game.score),
                        _stat('Best', _bestScore),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox.square(
                      dimension: boardSize,
                      child: GameBoard(
                        tiles: _game.board,
                        onDirection: _game.isGameOver ? null : _move,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Move left',
                          onPressed: _game.isGameOver
                              ? null
                              : () => _move(AxisDirection.left),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Move up',
                          onPressed: _game.isGameOver
                              ? null
                              : () => _move(AxisDirection.up),
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Move down',
                          onPressed: _game.isGameOver
                              ? null
                              : () => _move(AxisDirection.down),
                          icon: const Icon(Icons.arrow_downward),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Move right',
                          onPressed: _game.isGameOver
                              ? null
                              : () => _move(AxisDirection.right),
                          icon: const Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Swipe the board, use arrow keys, or tap the direction buttons.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
