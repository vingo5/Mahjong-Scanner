"""Top-level scoring entry point — combines batch 1 (composition) and
batch 2 (context) Fan patterns, picks the best-scoring decomposition."""

from .tile import Tile
from .game_context import GameContext
from .fan_calculator import (
    FanPattern, LIMIT_FAN,
    score_standard_decomposition, full_flush, half_flush,
)
from .fan_calculator_context import score_context_patterns


def calculate_fan_full(tiles: list[Tile], structures: list[dict], ctx: GameContext) -> dict:
    best: list[FanPattern] = []
    best_total = -1

    for structure in structures:
        if structure["type"] == "standard":
            for decomposition in structure["decompositions"]:
                batch1 = score_standard_decomposition(tiles, decomposition)

                # Limit hands (batch 1) short-circuit — don't stack context
                # fan on top of a limit hand, the limit already caps it
                if any(p.is_limit for p in batch1):
                    total = LIMIT_FAN
                    patterns = batch1
                else:
                    batch2 = score_context_patterns(tiles, decomposition, ctx)
                    patterns = batch1 + batch2
                    total = sum(p.fan for p in patterns)

                if total > best_total:
                    best_total = total
                    best = patterns

        elif structure["type"] == "seven_pairs":
            patterns = [FanPattern("Seven Pairs", 4)]
            if full_flush(tiles):
                patterns.append(FanPattern("Full Flush (Pure One Suit)", 6))
            elif half_flush(tiles):
                patterns.append(FanPattern("Half Flush (Mixed One Suit)", 3))
            if ctx.win_method.value == "self_draw":
                patterns.append(FanPattern("Self-Drawn (Zimo)", 1))
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
