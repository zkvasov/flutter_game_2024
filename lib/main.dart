// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  late Map<int, int> _gridData;

  late final List<int> _horizontalLastKeys;

  @override
  void initState() {
    super.initState();
    _gridData = Map.fromIterables(
      List.generate(
        16,
        (index) => index,
      ),
      List.generate(
        16,
        (index) => 0,
      ),
    );

// TODO: randomize
    // init random 2 values
    _gridData[1] = 2;
    _gridData[3] = 2;

    _horizontalLastKeys = _gridData.keys.where(
      (element) {
        return (element + 1) % 4 == 0;
      },
    ).toList();
  }

  void _onSwipe(DragUpdateDetails details) {
    const step = 150;
    final dx = details.delta.dx;
    final dy = details.delta.dy;

    log('dx: $dx, dy: $dy');

    final isHorizontal = dx.abs() > dy.abs();

    // Swiping in right direction.
    if (isHorizontal && dx > step) {
      log('Right');
      _calculateHorizontalRightSwipe();
      return;
    }

    // Swiping in left direction.
    if (isHorizontal && dx < -step) {
      log('Left');
      return;
    }

    // Swiping in down direction.
    if (dy > step) {
      log('Down');
      return;
    }

    // Swiping in top direction.
    if (dy < -step) {
      log('Top');
      return;
    }
  }

  void _calculateHorizontalRightSwipe() {
    for (var i = 0; i < _horizontalLastKeys.length - 1; i++) {
      final lastHorizontalIndex = _horizontalLastKeys[i];

      final indexSublist = List.generate(
        4,
        (index) => lastHorizontalIndex - index,
      );

      final sublist = _calculateFromLast(indexSublist
          .map(
            (index) => _gridData[index] ?? 0,
          )
          .toList());

      for (var j = 0; j < indexSublist.length; j++) {
        final index = indexSublist[j];
        _gridData[index] = sublist[j];
      }

      log('calculation');

      setState(() {});

      // final lastHorizontalValue = _gridData[lastHorizontalIndex];
      // final List<int> emptyPositions = [];
      // for (var j = lastHorizontalIndex; j < lastHorizontalIndex - 3; j--) {
      //   final value = _gridData[j];
      //   if (value == null || value == 0) {
      //     emptyPositions.add(j);
      //   }
      // }
    }
  }

  // 0 2 0 2 -> 0 0 0 4
  // 2 0 0 2 -> 0 0 0 4
  // 2 4 0 2 -> 0 2 4 2
  // 2 4 0 0 -> 0 2 4 0 -> 0 0 2 4

// TODO: 2 2 2 2
  List<int> _calculateFromLast(List<int> values) {
    final newValues = List<int>.from(values.where(
      (val) => val != 0,
    ));
    if (newValues.isEmpty) return [0, 0, 0, 0];

    if (newValues.length == 1) return [0, 0, 0, newValues.first];

    for (var i = newValues.length - 1; i > 0; i--) {
      final val = newValues[i];
      final previous = newValues[i - 1];
      if (val == previous) {
        newValues[i] = val * 2;
        newValues.removeAt(i - 1);
        i--;
        break;
      }
    }

    final length = newValues.length;
    final missedItemsLenght = 4 - length;
    for (var i = 0; i < missedItemsLenght; i++) {
      newValues.insert(0, 0);
    }

    return newValues;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                children: _gridData.entries.map(
                  (e) {
                    return _GridTile(
                      key: ValueKey(e.key.toString() + e.value.toString()),
                      value: e.value,
                    );
                  },
                ).toList()),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: _onSwipe,
            child: Container(
              color: Colors.green,
              height: 400,
              width: 400,
            ),
          )
        ],
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

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == 0;
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // TODO: random colors for values
        color: isEmpty ? Colors.grey : Colors.amber,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: isEmpty
          ? null
          : Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
