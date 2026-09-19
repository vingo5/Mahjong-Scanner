from dataclasses import dataclass
from enum import Enum


class Suit(Enum):
    MAN = "m"
    PIN = "p"
    SOU = "s"
    HONOR = "z"


class Honor(Enum):
    EAST = 1
    SOUTH = 2
    WEST = 3
    NORTH = 4
    WHITE_DRAGON = 5
    GREEN_DRAGON = 6
    RED_DRAGON = 7


@dataclass(frozen=True)
class Tile:
    suit: Suit
    value: int

    def __repr__(self):
        return f"{self.value}{self.suit.value}"

    @property
    def is_honor(self) -> bool:
        return self.suit == Suit.HONOR

    @property
    def is_terminal(self) -> bool:
        return not self.is_honor and self.value in (1, 9)

    @property
    def is_wind(self) -> bool:
        return self.is_honor and self.value <= 4

    @property
    def is_dragon(self) -> bool:
        return self.is_honor and self.value >= 5

    @classmethod
    def from_str(cls, s: str) -> "Tile":
        value = int(s[:-1])
        suit = Suit(s[-1])
        return cls(suit=suit, value=value)


def parse_hand(tiles_str: list[str]) -> list[Tile]:
    return [Tile.from_str(t) for t in tiles_str]
