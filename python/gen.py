W = 9
H = 8

import random
class Shuffle():
  def __init__(self, n):
    self.N = n
    self.i = 0
    self.l = range(n)

  def next(self):
    if self.i == self.N:
      return -1
    x = self.i + int(random.random() * (self.N - self.i))
    y = self.l[x]
    self.l[x] = self.l[self.i]
    self.i += 1
    return y
    
PINS = [
    [[0,1],   [1,2], [2,-1],  [0,0],   [1,0], [0,0],   [0,0],   [2,1]],
    [[0,0],   [0,2], [2, 0],  [1,0],   [0,0], [0,1],   [1,0],   [2,0]],
    [[1,0],   [0,1], [1, 0],  [1,1],   [0,1], [1,1],   [1,-1],  [1,0]],
    [[2,0],   [0,0], [0, 0],  [1,2],   [0,2], [2,1],   [1,-2],  [0,0]]]


def generatePins(pos_list):
  shuffle = Shuffle(12)
  pin = ['['] * 3
  for (pos, li) in pos_list:
    i = shuffle.next()
    pi = i % 4
    ci = i % 3
    x = pos / W + PINS[pi][li][0]
    y = pos % W + PINS[pi][li][1]
    pin[ci] += '[%d, %d], ' %(x,y)
  print '[%s], %s], %s]],' %(pin[0], pin[1], pin[2])
  

L = [[3,1,1], [7,4], [4,4,6], [0,1,7], [7,1], [6,4,4], [0,4,7], [1,1,3]]
DP =[[0, 0],  [0,0], [0,-2],  [-1,0],  [0,0], [0,-1],  [-1,-2], [0,0]]

def computeMask(l, dp):
  m = 0
  for i in reversed(l):
    m = (m << W) | i
  return m >> (-dp[0] * W - dp[1])

L_MASK = [computeMask(l, dp) for (l, dp) in zip(L, DP)]

BAD_CONFIG = set([])

def initBoard():
  board = (1 << W) - 1
  row = 1 << (W - 1)
  for i in xrange(H-2):
    board = (board << W) | row
  return (board << W) | ((1 << W) - 1)

def findNextPos(board):
  pos = W
  while (board >> pos) & 1 != 0:
    pos += 1
    if pos > W * (H-1):
      return -1
  return pos

def next(board, pos_list):
  if board in BAD_CONFIG:
    return False
  pos = findNextPos(board)
  if pos < 0:
    generatePins(pos_list)
    return True
  sh = Shuffle(8)
  for i in xrange(8):
    li = sh.next()
    l = L_MASK[li]
    if board & (l << pos) != 0: continue
    board = board | (l << pos)
    pos_list.append((pos, li))
    if next(board, pos_list):
      return True
    pos_list.pop()
    board = board - (l << pos)
  BAD_CONFIG.add(board)
  return False
      
for i in xrange(36):
  board = initBoard()
  next(board, []) 
