import './constants.dart';

class Block {
  final c_index;
  bool is_fixed;
  bool is_placed;
  int position;

  final _BlockGroup _group;
  int _g_index;
  _BlockProto _block;

  Block(this.c_index, this._group,
      {int index = 0, bool is_fixed = false, bool is_placed = false, int pos = 0}) {
    _g_index = index;
    _block = _group.get(_g_index);
    this.is_fixed = is_fixed;
    this.is_placed = is_placed;
    this.position = pos;
  }

  bool isSelected(int pos) {
    if (is_fixed || !is_placed || position > pos) return false;
    return _block.mask >> (pos - position) & BigInt.one != BigInt.zero;
  }

  BigInt shift(BigInt mask, int pos) {
    return pos >= 0 ? mask << pos : mask >> -pos;
  }

  BigInt getMask() {
    return is_placed ? shift(_block.mask, position) : _block.native_mask;
  }

  BigInt getHole() {
    return is_placed ? shift(_block.hole, position) : _block.native_hole;
  }

  BigInt place(int pos, List<BigInt> boards) {
    pos -= 2 * BOARD_W + 2;
    if (is_placed || shift(_block.mask, pos) & boards[0] != BigInt.zero) {
      return boards[0];
    }
    if (shift(_block.hole, pos) & boards[c_index] == BigInt.zero) {
      return boards[0];
    }
    this.position = pos;
    is_placed = true;
    return boards[0] | shift(_block.mask, pos);
  }

  BigInt replace(List<BigInt> boards) {
    if (is_fixed || !is_placed) {
      return boards[0];
    }
    is_placed = false;
    return boards[0] - shift(_block.mask, position);
  }

  BigInt rotate(List<BigInt> boards) {
    if (is_fixed) {
      return boards[0];
    }
    boards[0] = replace(boards);
    _g_index = (_g_index >= 4) ?
      _g_index = 4 + (_g_index + 1) % 4 : (_g_index + 1) % 4;
    _block = _group.get(_g_index);
    return boards[0];
  }

  BigInt flip(List<BigInt> boards) {
    if (is_fixed) {
      return boards[0];
    }
    boards[0] = replace(boards);
    _g_index = (_g_index + 4) % 8;
    _block = _group.get(_g_index);
    return boards[0];
  }

  void setIndex(int i) {
    _g_index = i;
    _block = _group.get(_g_index);
  }
}

// A immutable block with fixed rotation.
class _BlockProto {
  final List<int> _proto;
  final List<int> _hole;
  BigInt native_mask;
  BigInt native_hole;
  BigInt mask;
  BigInt hole;

  _BlockProto(this._proto, this._hole) {
    native_mask = _computeMask(NATIVE_W, true);
    native_hole = _computeMask(NATIVE_W, false);
    mask = _computeMask(BOARD_W, true);
    hole = _computeMask(BOARD_W, false);
  }

  BigInt _computeMask(int w, bool do_mask) {
    var m = BigInt.zero;
    for (int i = _proto.length - 1; i >= 0; --i) {
      var row = do_mask ? _proto[i] - _hole[i] : _hole[i];
      m = (m << w) | BigInt.from(row);
    }
    return m;
  }
}

// A block group contains a set of blocks that are connected through rotation.
class _BlockGroup {
  final _blocks = List<_BlockProto>();

  addBlock(_BlockProto b) => _blocks.add(b);

  get(int index) => _blocks[index % _blocks.length];
}

/** Block definitions */
const _BLOCK_CONFIG = [
  [3,1,1], [7,4], [4,4,6], [0,1,7], [7,1], [6,4,4], [0,4,7], [1,1,3]];

const _HOLE_CONFIGS = [
  [[2,0,0], [0,4], [0,0,2], [0,1,0], [0,1], [2,0,0], [0,4,0], [0,0,2]],
  [[1,0,0], [4,0], [0,0,4], [0,0,1], [1,0], [4,0,0], [0,0,4], [0,0,1]],
  [[0,1,0], [2,0], [0,4,0], [0,0,2], [2,0], [0,4,0], [0,0,2], [0,1,0]],
  [[0,0,1], [1,0], [4,0,0], [0,0,4], [4,0], [0,0,4], [0,0,1], [1,0,0]],
];

Block _buildBlock(int color, List block, List hole,
    {is_fixed = false, is_placed = false, pos = 0}) {
  var g = _BlockGroup();
  for (int r = 0; r < 8; ++r) {
    g.addBlock(_BlockProto(block[r], hole[r]));
  }
  return Block(color, g, is_fixed: is_fixed, is_placed: is_placed, pos: pos);
}

List<Block> buildBlocks() {
  List<Block> all_blocks = [];
  for (int c = 1; c <4; ++c) {
    for (var hole_config in _HOLE_CONFIGS) {
      all_blocks.add(_buildBlock(c, _BLOCK_CONFIG, hole_config));
    }
  }
  return all_blocks;
}