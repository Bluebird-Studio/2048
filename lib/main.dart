import 'package:flutter/material.dart';

void main() => runApp(const Game2048App());

class Game2048App extends StatelessWidget {
  const Game2048App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048',
      theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
      home: const Scaffold(
        body: Center(child: Text('2048 — game implementation coming next')),
      ),
    );
  }
}
