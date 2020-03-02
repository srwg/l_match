import 'package:flutter/material.dart';
import 'constants.dart';
import 'game_configs.dart';
import 'block.dart';

// The pixel diameter size of a circle
const CIRCLE_D = 45;

const NATIVE_D = 25;
// The pixel size of a home block
const NATIVE_B = NATIVE_D * NATIVE_W + 10;

// The Y positions for each section
const Y0 = 30;
const Y1 = Y0 + CIRCLE_D * BOARD_H;
const Y2 = Y1 + 10;

final List<Color> COLORS = [
  Colors.white,
  Colors.red,
  Colors.yellow,
  Colors.blueAccent,
];

class GameWidget extends StatelessWidget {
  final GamePainter painter = GamePainter();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: CustomPaint(
          size: Size(NATIVE_B * 4.0, Y2 + NATIVE_B * 3.0),
          painter: painter,
          isComplex: true,
          willChange: true),
      onTapUp: (TapUpDetails d) => painter.onRotate(d.localPosition),
      onLongPressStart: (LongPressStartDetails d) => painter.onFlip(d.localPosition),
      onPanStart: (DragStartDetails d) => painter.onDragBegin(d.localPosition),
      onPanUpdate: (DragUpdateDetails d) =>
          painter.onDragUpdate(d.localPosition),
      onPanEnd: (DragEndDetails d) => painter.onDragEnd(),
    );
  }
}

class GamePainter extends ChangeNotifier implements CustomPainter {
  List<BigInt> board;
  List<Block> blocks;
  final List<Block> home_blocks = [];
  Block moving_block;
  Offset pos;

  GamePainter() {
    blocks = buildBlocks();
    board = buildGame(blocks, home_blocks);
  }

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    _paintInBoard(BigInt.zero, BigInt.zero, 0, canvas, paint, target: 0);
    for (int i = 1; i < 4; ++i) {
      _paintInBoard(board[i], BigInt.zero, i, canvas, paint, padding: 0.25);
    }
    for (Block block in blocks) {
      if (block.is_placed) {
        _paintInBoard(block.getMask(), block.getHole(), block.c_index, canvas, paint,
        padding: 0.0);
      }
    }
    for (int y = 0; y < 3; ++y) {
      for (int x = 0; x < 4; ++x) {
        Block b = home_blocks[y * 4 + x];
        if (!b.is_placed && b != moving_block) {
          _paintAtXY(b.getMask(), b.getHole(), b.c_index, canvas, paint, x * NATIVE_B,
              Y2 + y * NATIVE_B, NATIVE_D);
        }
      }
    }
    Block b = moving_block;
    if (b != null) {
      _paintAtXY(b.getMask(), b.getHole(), b.c_index, canvas, paint,
          pos.dx.toInt() - CIRCLE_D * 2, pos.dy.toInt() - CIRCLE_D * 2, CIRCLE_D);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  void _paintInBoard(BigInt mask, BigInt hole, int c_index, Canvas canvas, Paint paint,
      {int target = 1, double padding = 0.02}) {
    paint.color = COLORS[c_index];
    for (int y = 0; y < BOARD_H - 1; ++y) {
      for (int x = 0; x < BOARD_W - 1; ++x) {
        int pos = y * BOARD_W + x;
        if (mask >> pos & BigInt.one == BigInt.from(target)) {
          canvas.drawRect(
              Rect.fromPoints(
                  Offset(CIRCLE_D * (x + padding), Y0 + CIRCLE_D * (y + padding)),
                  Offset(CIRCLE_D * (x + 1.0 - padding), Y0 + CIRCLE_D * (y + 1.0 - padding))),
              paint);
        }
        if (hole >> pos & BigInt.one == BigInt.one) {
          paint..style = PaintingStyle.stroke
          ..strokeWidth= CIRCLE_D * 0.2;
          canvas.drawRect(
              Rect.fromPoints(
                  Offset(CIRCLE_D * (x + 0.1), Y0 + CIRCLE_D * (y + 0.1)),
                  Offset(CIRCLE_D * (x + 0.9), Y0 + CIRCLE_D * (y + 0.9))),
              paint);
          paint..style = PaintingStyle.fill;
        }
      }
    }
  }

  void _paintAtXY(
      BigInt mask, BigInt hole, int color, Canvas canvas, Paint paint, int dx, int dy,
      int size) {
    paint.color = COLORS[color];
    for (int y = 0; y < NATIVE_W; ++y) {
      for (int x = 0; x < NATIVE_W; ++x) {
        int pos = y * NATIVE_W + x;
        if (mask >> pos & BigInt.one == BigInt.one) {
          canvas.drawRect(
              Rect.fromPoints(
                  Offset(dx + size * x * 1.0, dy + size * y * 1.0),
                  Offset(dx + size * (x + 1.0), dy + size * (y + 1.0))),
              paint);
        }
        if (hole >> pos & BigInt.one == BigInt.one) {
          paint..style = PaintingStyle.stroke
          ..strokeWidth=size * 0.2;
          canvas.drawRect(
              Rect.fromPoints(
                  Offset(dx + size * (x + 0.1), dy + size * (y + 0.1)),
                  Offset(dx + size * (x + 0.9), dy + size * (y + 0.9))),
              paint);
          paint..style = PaintingStyle.fill;
        }
      }
    }
  }

  Block _findSelected(Offset offset) {
    if (offset.dy >= Y2) {
      // search in home area.
      int iy = (offset.dy - Y2).toInt() ~/ NATIVE_B;
      int ix = offset.dx.toInt() ~/ NATIVE_B;
      int home = iy * 4 + ix;
      return home < home_blocks.length && !home_blocks[home].is_placed
          ? home_blocks[home]
          : null;
    } else if (offset.dy >= Y0 && offset.dy < Y1) {
      int iy = (offset.dy - Y0).toInt() ~/ CIRCLE_D;
      int ix = offset.dx.toInt() ~/ CIRCLE_D;
      int pos = iy * BOARD_W + ix;
      for (Block b in blocks) {
        if (b.is_placed && !b.is_fixed && b.isSelected(pos)) {
          return b;
        }
      }
    }
    return null;
  }

  void onRotate(Offset offset) {
    Block b = _findSelected(offset);
    if (b != null) {
      board[0] = b.rotate(board);
      notifyListeners();
    }
  }

  void onFlip(Offset offset) {
    Block b = _findSelected(offset);
    if (b != null) {
      board[0] = b.flip(board);
      notifyListeners();
    }
  }

  void onDragBegin(Offset offset) {
    pos = offset;
    moving_block = _findSelected(offset);
    if (moving_block != null) {
      board[0] = moving_block.replace(board);
    }
  }

  void onDragUpdate(Offset offset) {
    pos = offset;
    notifyListeners();
  }

  void onDragEnd() {
    if (moving_block != null) {
      if (pos.dy >= Y0 && pos.dy < Y1) {
        int iy = ((pos.dy - Y0) / CIRCLE_D + 0.5).toInt();
        int ix = (pos.dx / CIRCLE_D + 0.5).toInt();
        int p = iy * BOARD_W + ix;
        board[0] = moving_block.place(p, board);
      } else {
        board[0] = moving_block.replace(board);
      }
      moving_block = null;
      notifyListeners();
    }
  }

  @override
  bool hitTest(Offset p) => null;

  @override
  // TODO: implement semanticsBuilder
  get semanticsBuilder => null;

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) {
    // TODO: implement shouldRebuildSemantics
    return true;
  }
}
