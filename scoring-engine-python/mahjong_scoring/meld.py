from dataclasses import dataclass
from enum import Enum
from .tile import Tile


class MeldType(Enum):
    CHOW = "chow"
    PUNG = "pung"
    KONG = "kong"
    PAIR = "pair"


@dataclass(frozen=True)
class Meld:
    type: MeldType
    tiles: tuple[Tile, ...]
    concealed: bool = True

    def __repr__(self):
        return f"{self.type.value}({','.join(map(repr, self.tiles))})"
