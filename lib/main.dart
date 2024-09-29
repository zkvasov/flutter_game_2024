import 'dart:developer';
import 'dart:math' as math;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '2048'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const _gridSize = 4;

  final math.Random random = math.Random();
  late List<List<int>> _gridData;

  // Track swipe movement
  Offset _startSwipeOffset = Offset.zero;

  @override
  void initState() {
    super.initState();

    _setEmptyGrid();
  }

  void _setEmptyGrid() {
    _gridData = List.generate(_gridSize, (_) => List.filled(_gridSize, 0));

    // add 2 random value tiles
    _addRandomTile();
    _addRandomTile();
  }

  void _calculateSwipeRight() {
    setState(() {
      for (int i = 0; i < _gridSize; i++) {
        _gridData[i] = _merge(_gridData[i].reversed.toList()).reversed.toList();
      }
    });
  }

  void _calculateSwipeLeft() {
    setState(() {
      for (int i = 0; i < _gridSize; i++) {
        _gridData[i] = _merge(_gridData[i]);
      }
    });
  }

  void _calculateSwipeUp() {
    setState(() {
      _gridData = _transpose(_gridData);
      _calculateSwipeLeft();
      _gridData = _transpose(_gridData);
    });
  }

  void _calculateSwipeDown() {
    setState(() {
      _gridData = _transpose(_gridData);
      _calculateSwipeRight();
      _gridData = _transpose(_gridData);
    });
  }

  List<int> _merge(List<int> row) {
    // First, remove all zeros
    row = row.where((x) => x != 0).toList();

    // Merge adjacent equal numbers
    for (int i = 0; i < row.length - 1; i++) {
      if (row[i] == row[i + 1]) {
        row[i] *= 2;
        row[i + 1] = 0;
      }
    }

    // Remove zeros again after merge
    row = row.where((x) => x != 0).toList();

    // Add zeros to the right to make the row size 4 again
    while (row.length < _gridSize) {
      row.add(0);
    }

    return row;
  }

  /// swaps rows and columns
  List<List<int>> _transpose(List<List<int>> matrix) {
    List<List<int>> transposed = List.generate(
      _gridSize,
      (_) => List.filled(_gridSize, 0),
    );
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        transposed[i][j] = matrix[j][i];
      }
    }
    return transposed;
  }

  void _addRandomTile() {
    List<math.Point<int>> emptyTiles = [];

    // Find all empty positions (0 values)
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (_gridData[i][j] == 0) {
          emptyTiles.add(math.Point(i, j));
        }
      }
    }

    // Randomly choose an empty position
    final randomTile = emptyTiles[random.nextInt(emptyTiles.length)];

    // Set value as '2' (90% of the time) or '4' (10% of the time)
    _gridData[randomTile.x][randomTile.y] =
        random.nextDouble() < 0.9 ? 2 : _gridSize;
  }

  void _onSwipe(DragEndDetails details) {
    if (_startSwipeOffset != Offset.zero) return;

    const step = 10;
    final dx = details.velocity.pixelsPerSecond.dx - _startSwipeOffset.dx;
    final dy = details.velocity.pixelsPerSecond.dy - _startSwipeOffset.dy;
    final isHorizontal = dx.abs() > dy.abs();

    // Create a copy of the current grid
    final previousGrid = _gridData.map((row) => List<int>.from(row)).toList();

    // Swiping in right direction.
    if (isHorizontal && dx > step) {
      log('Right');
      _calculateSwipeRight();
    } else
    // Swiping in left direction.
    if (isHorizontal && dx < -step) {
      log('Left');
      _calculateSwipeLeft();
    } else
    // Swiping in down direction.
    if (dy > step) {
      log('Down');
      _calculateSwipeDown();
    } else
    // Swiping in top direction.
    if (dy < -step) {
      log('Up');
      _calculateSwipeUp();
    }

    // Check if the grid has changed
    if (!_isGridEqual(previousGrid, _gridData)) {
      _addRandomTile();
    }

    // Check if there is a 2048 tile (player wins)
    if (_checkForWin()) {
      _showWinDialog();
    }

    // Check if the game is over
    if (_isGameOver()) {
      _showGameOverDialog();
    }

    _startSwipeOffset = Offset.zero;
  }

  void onSwipeStart(DragStartDetails details) {
    _startSwipeOffset = details.localPosition;
  }

  bool _isGridEqual(List<List<int>> grid1, List<List<int>> grid2) {
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (grid1[i][j] != grid2[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  bool _isGameOver() {
    // Check if any tile is 0 (empty)
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (_gridData[i][j] == 0) return false;
      }
    }

    // Check if any adjacent tiles can be merged horizontally
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize - 1; j++) {
        if (_gridData[i][j] == _gridData[i][j + 1]) return false;
      }
    }

    // Check if any adjacent tiles can be merged vertically
    for (int i = 0; i < _gridSize - 1; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (_gridData[i][j] == _gridData[i + 1][j]) return false;
      }
    }

    // If no empty tiles and no merges are possible, the game is over
    return true;
  }

  /// Show a simple game-over dialog
  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Game Over"),
          content: const Text("No more moves are possible."),
          actions: [
            TextButton(
              child: const Text("Restart"),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _setEmptyGrid();
                });
              },
            ),
          ],
        );
      },
    );
  }

  /// Check if any tile is 2048
  bool _checkForWin() {
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (_gridData[i][j] == 2048) {
          return true;
        }
      }
    }
    return false;
  }

  /// Show a dialog indicating the player has won
  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("You Win!"),
          content: const Text("You've reached the 2048 tile!"),
          actions: [
            TextButton(
              child: const Text("Keep Playing"),
              onPressed: () {
                Navigator.of(context).pop();
                // Allow the user to continue playing if they want
              },
            ),
            TextButton(
              child: const Text("Restart"),
              onPressed: () {
                Navigator.of(context).pop();
                _setEmptyGrid();
              },
            ),
          ],
        );
      },
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Restart"),
          content: const Text("Are you sure you want to restart the game?"),
          actions: [
            TextButton(
              child: const Text("Restart"),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _setEmptyGrid();
                });
              },
            ),
            TextButton(
              child: const Text("Continue"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: Text(widget.title),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanEnd: _onSwipe,
        onPanStart: (details) {},
        child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: _gridSize,
            children: _gridData.expand((n) => n).mapIndexed(
              (index, item) {
                return _GridTile(
                  value: item,
                );
              },
            ).toList()),
      ),
      floatingActionButton: ElevatedButton(
        onPressed: _showRestartDialog,
        child: const Text('Restart'),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final int value;

  const _GridTile({
    super.key,
    required this.value,
  });

  Color _getTileColor(int value) {
    switch (value) {
      case 0:
        return Colors.grey;
      case 2:
        return Colors.orange[200]!;
      case 4:
        return Colors.orange[300]!;
      case 8:
        return Colors.orange[400]!;
      case 16:
        return Colors.orange[500]!;
      case 32:
        return Colors.orange[600]!;
      case 64:
        return Colors.orange[700]!;
      case 128:
        return Colors.orange[800]!;
      case 256:
        return Colors.orange[900]!;
      case 512:
        return Colors.red[700]!;
      case 1024:
        return Colors.red[800]!;
      case 2048:
        return Colors.red[900]!;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == 0;
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getTileColor(value),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: isEmpty
          ? null
          : AutoSizeText(
              value.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
