import 'constants.dart';
import 'block.dart';

/** Compute the board for a rectangular board */
BigInt buildRectangularGameBoard() {
  var board = BigInt.from(1 << BOARD_W - 1);
  var row = 1 << (BOARD_W - 1);
  for (int h = 0; h < BOARD_H; ++h) {
    board = (board << BOARD_W) | BigInt.from(row);
  }
  return board;
}

/** Game configuration */
const GAME_PINS = [
  [[0, 0], [4, 1], [1, 6], [5, 6]],
  [[4, 0], [5, 2], [1, 3], [2, 7]],
  [[1, 2], [3, 3], [4, 4], [1, 7]],
];

BigInt buildGamePins(List pos) {
  var board = BigInt.zero;
  var rows = List<int>();
  for (int r=0; r < BOARD_H; ++r) {
    var x = 0;
    for (var p in pos) {
      if (p[0] == r) {
        x += 1 << p[1];
      }
    }
    rows.add(x);
  }
  for (int r in rows.reversed) {
    board = (board << BOARD_W) | BigInt.from(r);
  }
  return board;
}

List<BigInt> buildGame(List<Block> blocks, List<Block> blocks_home) {
  for (int i = 0; i < blocks.length; ++i) {
    blocks_home.add(blocks[i]);
  }
  List<BigInt> boards = [];
  boards.add(buildRectangularGameBoard());
  for (var pins in GAME_PINS) {
    var pin_b = buildGamePins(pins);
    boards[0] |= pin_b;
    boards.add(pin_b);
  }
  return boards;
}
