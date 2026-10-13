import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A presentation-only 2048 board. Game rules remain in the game engine.
class GameBoard extends StatelessWidget {
  const GameBoard({super.key, required this.tiles, this.onDirection});

  static const _moveLeft = CustomSemanticsAction(label: 'Move left');
  static const _moveRight = CustomSemanticsAction(label: 'Move right');
  static const _moveUp = CustomSemanticsAction(label: 'Move up');
  static const _moveDown = CustomSemanticsAction(label: 'Move down');

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
        child: Focus(
          autofocus: onDirection != null,
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent || onDirection == null) {
              return KeyEventResult.ignored;
            }
            final direction = switch (event.logicalKey) {
              LogicalKeyboardKey.arrowLeft => AxisDirection.left,
              LogicalKeyboardKey.arrowRight => AxisDirection.right,
              LogicalKeyboardKey.arrowUp => AxisDirection.up,
              LogicalKeyboardKey.arrowDown => AxisDirection.down,
              _ => null,
            };
            if (direction == null) return KeyEventResult.ignored;
            onDirection!(direction);
            return KeyEventResult.handled;
          },
          child: Builder(
            builder: (focusContext) => SizedBox.square(
              dimension: side,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Focus.of(focusContext).requestFocus(),
                onPanStart: (_) => drag = Offset.zero,
                onPanUpdate: (details) => drag += details.delta,
                onPanEnd: (_) {
                  if (drag.distance < 24 || onDirection == null) return;
                  final horizontal = drag.dx.abs() > drag.dy.abs();
                  onDirection!(horizontal
                      ? (drag.dx > 0 ? AxisDirection.right : AxisDirection.left)
                      : (drag.dy > 0 ? AxisDirection.down : AxisDirection.up));
                },
                child: Semantics(
                  label: '2048 game board',
                  hint: 'Swipe, use arrow keys, or choose a move action',
                  explicitChildNodes: true,
                  customSemanticsActions: onDirection == null
                      ? null
                      : {
                          _moveLeft: () => onDirection!(AxisDirection.left),
                          _moveRight: () => onDirection!(AxisDirection.right),
                          _moveUp: () => onDirection!(AxisDirection.up),
                          _moveDown: () => onDirection!(AxisDirection.down),
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
                          for (final (rowIndex, row) in tiles.indexed)
                            Expanded(
                              child: Row(
                                children: [
                                  for (final (columnIndex, value) in row.indexed)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Semantics(
                                          label: value == 0
                                              ? 'Empty tile, row ${rowIndex + 1}, column ${columnIndex + 1}'
                                              : 'Tile $value, row ${rowIndex + 1}, column ${columnIndex + 1}',
                                          child: ExcludeSemantics(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: value == 0
                                                    ? theme.colorScheme.surface
                                                    : theme.colorScheme.primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    value == 0 ? '' : '$value',
                                                    style: theme
                                                        .textTheme.headlineMedium
                                                        ?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: theme.colorScheme
                                                          .onPrimaryContainer,
                                                    ),
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
            ),
          ),
        ),
      );
    });
  }
}
