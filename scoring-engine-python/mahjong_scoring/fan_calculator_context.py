"""
Batch 2: context-dependent Fan patterns — need GameContext (wind/seat/
win-method/concealed status) in addition to the tiles and decomposition.
"""

from .tile import Tile, Suit
from .meld import Meld, MeldType
from .game_context import GameContext, WinMethod
from .fan_calculator import FanPattern, all_pungs


def _wind_value(honor) -> int:
    return honor.value


def prevalent_wind_pung(decomposition: list[Meld], ctx: GameContext) -> bool:
    return any(
        m.type in (MeldType.PUNG, MeldType.KONG)
        and m.tiles[0].is_wind
        and m.tiles[0].value == _wind_value(ctx.prevalent_wind)
        for m in decomposition
    )


def seat_wind_pung(decomposition: list[Meld], ctx: GameContext) -> bool:
    return any(
        m.type in (MeldType.PUNG, MeldType.KONG)
        and m.tiles[0].is_wind
        and m.tiles[0].value == _wind_value(ctx.seat_wind)
        for m in decomposition
    )


def all_chows(decomposition: list[Meld]) -> bool:
    non_pair = [m for m in decomposition if m.type != MeldType.PAIR]
    pair = next((m for m in decomposition if m.type == MeldType.PAIR), None)
    if len(non_pair) != 4 or pair is None:
        return False
    return all(m.type == MeldType.CHOW for m in non_pair) and not pair.tiles[0].is_honor


def self_drawn(ctx: GameContext) -> bool:
    return ctx.win_method == WinMethod.SELF_DRAW


def fully_concealed(ctx: GameContext) -> bool:
    return ctx.is_concealed


def all_terminals_and_honors(tiles: list[Tile]) -> bool:
    """Every tile is a terminal (1/9) or an honor. Chows can never satisfy
    this — only 1/9 count as terminals, and a chow always spans a middle
    value (2-8) too — so in practice this only ever fires on all-pung hands."""
    if not all(t.is_terminal or t.is_honor for t in tiles):
        return False
    return any(not t.is_honor for t in tiles)  # must include at least one terminal


def pure_straight(decomposition: list[Meld]) -> bool:
    chows = [m for m in decomposition if m.type == MeldType.CHOW]
    by_suit: dict[Suit, set[int]] = {}
    for c in chows:
        starts = by_suit.setdefault(c.tiles[0].suit, set())
        starts.add(c.tiles[0].value)
    return any({1, 4, 7} <= starts for starts in by_suit.values())


def score_context_patterns(
    tiles: list[Tile],
    decomposition: list[Meld],
    ctx: GameContext,
) -> list[FanPattern]:
    patterns: list[FanPattern] = []

    if all_terminals_and_honors(tiles):
        patterns.append(FanPattern("All Terminals and Honors", 10))

    if pure_straight(decomposition):
        patterns.append(FanPattern("Pure Straight (1-9)", 3))

    if prevalent_wind_pung(decomposition, ctx):
        patterns.append(FanPattern("Prevalent Wind Pung", 1))

    if seat_wind_pung(decomposition, ctx):
        patterns.append(FanPattern("Seat Wind Pung", 1))

    if all_chows(decomposition):
        patterns.append(FanPattern("All Chows (Ping Hu)", 1))

    if self_drawn(ctx):
        patterns.append(FanPattern("Self-Drawn (Zimo)", 1))

    if fully_concealed(ctx) and ctx.win_method == WinMethod.DISCARD:
        patterns.append(FanPattern("Fully Concealed Hand", 1))

    return patterns
