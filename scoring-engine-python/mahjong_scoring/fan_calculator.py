"""
Batch 1: composition-based Fan patterns — evaluated purely from the tiles
and meld decomposition, no game context (wind/seat/win-method) needed yet.
Those come in batch 2.

Fan values here follow a common Hong Kong scoring reference. House rules
vary on exact numbers (esp. Seven Pairs and Small Three Dragons) — these
are easy to retune later since every pattern is an isolated function.
"""

from dataclasses import dataclass
from .tile import Tile, Suit
from .meld import Meld, MeldType

LIMIT_FAN = 13  # traditional HK "limit" — max payout regardless of exact fan count


@dataclass
class FanPattern:
    name: str
    fan: int
    is_limit: bool = False


def _suits_used(tiles: list[Tile]) -> set[Suit]:
    return {t.suit for t in tiles}


def _dragon_pungs(decomposition: list[Meld]) -> list[Meld]:
    return [
        m for m in decomposition
        if m.type in (MeldType.PUNG, MeldType.KONG) and m.tiles[0].is_dragon
    ]


def all_honors(tiles: list[Tile]) -> bool:
    """Every tile is an honor (wind/dragon). Limit hand."""
    return all(t.is_honor for t in tiles)


def big_three_dragons(decomposition: list[Meld]) -> bool:
    """Pungs/kongs of all three dragons. Limit hand."""
    dragon_pungs = _dragon_pungs(decomposition)
    dragon_values = {m.tiles[0].value for m in dragon_pungs}
    return len(dragon_pungs) == 3 and dragon_values == {5, 6, 7}


def small_three_dragons(decomposition: list[Meld]) -> bool:
    """Two dragon pungs + the third dragon as the pair."""
    dragon_pungs = _dragon_pungs(decomposition)
    pair = next((m for m in decomposition if m.type == MeldType.PAIR), None)
    if len(dragon_pungs) != 2 or pair is None:
        return False
    return pair.tiles[0].is_dragon


def all_pungs(decomposition: list[Meld]) -> bool:
    """Toitoi — every meld (not the pair) is a pung or kong, no chows."""
    non_pair = [m for m in decomposition if m.type != MeldType.PAIR]
    return len(non_pair) == 4 and all(m.type in (MeldType.PUNG, MeldType.KONG) for m in non_pair)


def full_flush(tiles: list[Tile]) -> bool:
    """Pure One Suit — every tile the same suit, no honors."""
    suits = _suits_used(tiles)
    return suits == {list(suits)[0]} and Suit.HONOR not in suits and len(suits) == 1


def half_flush(tiles: list[Tile]) -> bool:
    """Mixed One Suit — one suit plus honors (but not honors-only)."""
    suits = _suits_used(tiles)
    non_honor_suits = suits - {Suit.HONOR}
    return len(non_honor_suits) == 1 and Suit.HONOR in suits


def score_standard_decomposition(tiles: list[Tile], decomposition: list[Meld]) -> list[FanPattern]:
    """Evaluate one specific meld decomposition of a standard (4 melds + pair) hand."""

    # Limit hands short-circuit — no stacking beyond the limit itself
    if all_honors(tiles):
        return [FanPattern("All Honors", LIMIT_FAN, is_limit=True)]

    if big_three_dragons(decomposition):
        return [FanPattern("Big Three Dragons", LIMIT_FAN, is_limit=True)]

    patterns: list[FanPattern] = []

    if all_pungs(decomposition):
        patterns.append(FanPattern("All Pungs (Toitoi)", 3))

    if full_flush(tiles):
        patterns.append(FanPattern("Full Flush (Pure One Suit)", 6))
    elif half_flush(tiles):
        patterns.append(FanPattern("Half Flush (Mixed One Suit)", 3))

    if small_three_dragons(decomposition):
        # Replaces individual dragon-pung fan for the two pungs involved —
        # avoids double-counting the same two pungs both individually and
        # as part of the combo.
        patterns.append(FanPattern("Small Three Dragons", 5))
    else:
        for pung in _dragon_pungs(decomposition):
            patterns.append(FanPattern(f"Dragon Pung ({pung.tiles[0]!r})", 1))

    return patterns


def calculate_fan(tiles: list[Tile], structures: list[dict]) -> dict:
    """
    Top-level entry point. `structures` is the `structures` list from
    validate_winning_hand(). Picks the highest-scoring interpretation
    when a hand has multiple valid decompositions.
    """

    best: list[FanPattern] = []
    best_total = -1

    for structure in structures:
        if structure["type"] == "standard":
            for decomposition in structure["decompositions"]:
                patterns = score_standard_decomposition(tiles, decomposition)
                total = LIMIT_FAN if any(p.is_limit for p in patterns) else sum(p.fan for p in patterns)
                if total > best_total:
                    best_total = total
                    best = patterns

        elif structure["type"] == "seven_pairs":
            patterns = [FanPattern("Seven Pairs", 4)]
            if full_flush(tiles):
                patterns.append(FanPattern("Full Flush (Pure One Suit)", 6))
            elif half_flush(tiles):
                patterns.append(FanPattern("Half Flush (Mixed One Suit)", 3))
            total = sum(p.fan for p in patterns)
            if total > best_total:
                best_total = total
                best = patterns

        elif structure["type"] == "thirteen_orphans":
            patterns = [FanPattern("Thirteen Orphans", LIMIT_FAN, is_limit=True)]
            if LIMIT_FAN > best_total:
                best_total = LIMIT_FAN
                best = patterns

    return {
        "patterns": [{"name": p.name, "fan": p.fan, "is_limit": p.is_limit} for p in best],
        "total_fan": best_total if best_total >= 0 else 0,
    }
