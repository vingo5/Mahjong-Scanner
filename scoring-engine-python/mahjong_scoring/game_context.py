"""Game-state inputs needed for context-dependent Fan patterns (batch 2)."""

from dataclasses import dataclass
from enum import Enum
from .tile import Honor


class WinMethod(Enum):
    SELF_DRAW = "self_draw"   # Zimo
    DISCARD = "discard"        # won off another player's discard


@dataclass
class GameContext:
    seat_wind: Honor           # player's own seat wind (East/South/West/North)
    prevalent_wind: Honor      # the round wind
    win_method: WinMethod
    is_concealed: bool         # True if hand had zero exposed (called) melds
