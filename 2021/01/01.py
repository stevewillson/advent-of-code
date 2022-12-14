#! /usr/bin/env python3

import sys
import time
from typing import Callable, Iterable, List, Tuple, TypeVar

test = False
debug = False
stdin = False
INFILENAME = "01.txt"
for arg in sys.argv:
    if arg == "--test":
        test = True
        INFILENAME = "01.test.txt"
    if arg == "--debug":
        debug = True
    if arg == "--stdin":
        stdin = True

K = TypeVar("K")
V = TypeVar("V")


def maplist(fn: Callable[[K], V], l: Iterable[K]) -> List[V]:
    return list(map(fn, l))


def window(iterable: List[K], n: int) -> Iterable[Tuple[K, ...]]:
    """
    Return a sliding window of size ``n`` of the given iterable.
    """
    for start_idx in range(len(iterable) - n + 1):
        yield tuple(iterable[start_idx + idx] for idx in range(n))


print(f"\n{'=' * 30}\n")

# Input parsing
input_start = time.time()
if stdin:
    lines: List[str] = [l.strip() for l in sys.stdin.readlines()]
else:
    with open(INFILENAME) as f:
        lines: List[str] = [l.strip() for l in f.readlines()]

seq = [int(x) for x in lines]

input_end = time.time()

# Shared
########################################################################################
shared_start = time.time()

shared_end = time.time()

# Part 1
########################################################################################
print("Part 1:")


def part1() -> int:
    ans = 0

    for i, j in zip(seq, seq[1:]):
        if j > i:
            ans += 1

    return ans


part1_start = time.time()
ans_part1 = part1()
part1_end = time.time()
print(ans_part1)

# Store the attempts that failed here.
tries = []
print("Tries Part 1:", tries)
assert ans_part1 not in tries, "Same as an incorrect answer!"


# Regression Test
assert test or ans_part1 == 1374

# Part 2
########################################################################################
print("\nPart 2:")


def part2() -> int:
    ans = 0

    windows = maplist(sum, window(seq, 3))
    for i, j in zip(windows, windows[1:]):
        if j > i:
            ans += 1

    return ans


part2_start = time.time()
ans_part2 = part2()
part2_end = time.time()
print(ans_part2)

# Store the attempts that failed here.
tries2 = []
print("Tries Part 2:", tries2)
assert ans_part2 not in tries2, "Same as an incorrect answer!"

# Regression Test
assert test or ans_part2 == 1418

if debug:
    input_parsing = input_end - input_start
    shared = shared_end - shared_start
    part1_time = part1_end - part1_start
    part2_time = part2_end - part2_start
    print()
    print("DEBUG:")
    print(f"Input parsing: {input_parsing * 1000}ms")
    print(f"Shared: {shared * 1000}ms")
    print(f"Part 1: {part1_time * 1000}ms")
    print(f"Part 2: {part2_time * 1000}ms")
    print(
        f"TOTAL: {(input_parsing + shared + part1_time + part2_time) * 1000}ms")
