import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A presentation-only 2048 board. Game rules remain in the game engine.
class GameBoard extends StatelessWidget {
  const GameBoard({super.key, required this.tiles, this.onDirection});

  /// Four rows of four tile values; zero represents an empty cell.
  final List<List<int>> tiles;
  final ValueChanged<AxisDirection>? onDirection;

  @override
  Widget build(BuildContext context) {
    assert(tiles.length == 4 && tiles.every((row) => row.length == 4));
    final theme = Theme.of(context);
    Offset drag = Offset.zero;
    return LayoutBuilder(builder: (context, constraints) {
      final side = math.min(constraints.maxWidth, constraints.maxHeight);
      if (!side.isFinite || side <= 0) return const SizedBox.shrink();
      return Center(
        child: SizedBox.square(
          dimension: side,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) => drag = Offset.zero,
            onPanUpdate: (details) => drag += details.delta,
            onPanEnd: (_) {
              if (drag.distance < 24 || onDirection == null) return;
              final horizontal = drag.dx.abs() > drag.dy.abs();
              onDirection!(horizontal
                  ? (drag.dx > 0 ? AxisDirection.right : AxisDirection.left)
                  : (drag.dy > 0 ? AxisDirection.down : AxisDirection.up));
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    for (final row in tiles)
                      Expanded(
                        child: Row(
                          children: [
                            for (final value in row)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Semantics(
                                    label: value == 0 ? 'Empty tile' : 'Tile $value',
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: value == 0
                                            ? theme.colorScheme.surface
                                            : theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            value == 0 ? '' : '$value',
                                            style: theme.textTheme.headlineMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
