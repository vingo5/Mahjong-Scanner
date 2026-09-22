from collections import Counter
from .tile import Tile, Suit
from .meld import Meld, MeldType


def is_standard_winning_hand(tiles: list[Tile]) -> list[list[Meld]] | None:
    if len(tiles) != 14:
        return None

    counts = Counter(tiles)
    solutions: list[list[Meld]] = []

    for pair_tile in set(t for t in counts if counts[t] >= 2):
        remaining = counts.copy()
        remaining[pair_tile] -= 2
        if remaining[pair_tile] == 0:
            del remaining[pair_tile]

        melds: list[Meld] = []
        if _decompose_melds(remaining, melds, target_melds=4):
            pair = Meld(type=MeldType.PAIR, tiles=(pair_tile, pair_tile))
            solutions.append(melds + [pair])

    return solutions if solutions else None


def _decompose_melds(counts: Counter, found: list[Meld], target_melds: int) -> bool:
    if len(found) == target_melds:
        return sum(counts.values()) == 0

    if not counts:
        return False

    tile = min(counts.keys(), key=lambda t: (t.suit.value, t.value))

    # --- Pung ---
    if counts[tile] >= 3:
        counts[tile] -= 3
        removed = counts[tile] == 0
        if removed:
            del counts[tile]  # BUGFIX: must purge zero-count keys, or `min()`
                               # keeps re-selecting this exhausted tile forever

        found.append(Meld(type=MeldType.PUNG, tiles=(tile, tile, tile)))
        if _decompose_melds(counts, found, target_melds):
            return True
        found.pop()

        if removed:
            counts[tile] = 3
        else:
            counts[tile] += 3

    # --- Chow (sequence) — suited tiles only ---
    if tile.suit != Suit.HONOR and tile.value <= 7:
        t2 = Tile(tile.suit, tile.value + 1)
        t3 = Tile(tile.suit, tile.value + 2)
        if counts.get(t2, 0) >= 1 and counts.get(t3, 0) >= 1:
            counts[tile] -= 1
            counts[t2] -= 1
            counts[t3] -= 1
            for t in (tile, t2, t3):
                if counts[t] == 0:
                    del counts[t]
            found.append(Meld(type=MeldType.CHOW, tiles=(tile, t2, t3)))
            if _decompose_melds(counts, found, target_melds):
                return True
            found.pop()
            counts[tile] = counts.get(tile, 0) + 1
            counts[t2] = counts.get(t2, 0) + 1
            counts[t3] = counts.get(t3, 0) + 1

    return False


def is_seven_pairs(tiles: list[Tile]) -> bool:
    if len(tiles) != 14:
        return False
    counts = Counter(tiles)
    return len(counts) == 7 and all(c == 2 for c in counts.values())


THIRTEEN_ORPHAN_TILES = {
    Tile(Suit.MAN, 1), Tile(Suit.MAN, 9),
    Tile(Suit.PIN, 1), Tile(Suit.PIN, 9),
    Tile(Suit.SOU, 1), Tile(Suit.SOU, 9),
    Tile(Suit.HONOR, 1), Tile(Suit.HONOR, 2), Tile(Suit.HONOR, 3), Tile(Suit.HONOR, 4),
    Tile(Suit.HONOR, 5), Tile(Suit.HONOR, 6), Tile(Suit.HONOR, 7),
}


def is_thirteen_orphans(tiles: list[Tile]) -> bool:
    if len(tiles) != 14:
        return False
    counts = Counter(tiles)
    if set(counts.keys()) != THIRTEEN_ORPHAN_TILES:
        return False
    pair_count = sum(1 for c in counts.values() if c == 2)
    single_count = sum(1 for c in counts.values() if c == 1)
    return pair_count == 1 and single_count == 12


def validate_winning_hand(tiles: list[Tile]) -> dict:
    result = {"is_valid": False, "structures": []}

    standard = is_standard_winning_hand(tiles)
    if standard:
        result["is_valid"] = True
        result["structures"].append({"type": "standard", "decompositions": standard})

    if is_seven_pairs(tiles):
        result["is_valid"] = True
        result["structures"].append({"type": "seven_pairs"})

    if is_thirteen_orphans(tiles):
        result["is_valid"] = True
        result["structures"].append({"type": "thirteen_orphans"})

    return result
