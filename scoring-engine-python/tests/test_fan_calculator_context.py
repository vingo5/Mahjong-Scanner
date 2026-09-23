from mahjong_scoring.tile import parse_hand, Honor
from mahjong_scoring.hand_validator import validate_winning_hand
from mahjong_scoring.game_context import GameContext, WinMethod
from mahjong_scoring.scoring import calculate_fan_full


def score(tiles_str, ctx):
    hand = parse_hand(tiles_str)
    result = validate_winning_hand(hand)
    assert result["is_valid"], f"hand should be valid: {tiles_str}"
    return calculate_fan_full(hand, result["structures"], ctx)


def test_seat_wind_pung():
    ctx = GameContext(
        seat_wind=Honor.EAST, prevalent_wind=Honor.SOUTH,
        win_method=WinMethod.DISCARD, is_concealed=False,
    )
    fan = score([
        "1z", "1z", "1z",
        "4p", "5p", "6p",
        "2s", "3s", "4s",
        "5s", "6s", "7s",
        "9m", "9m",
    ], ctx)
    names = [p["name"] for p in fan["patterns"]]
    assert "Seat Wind Pung" in names
    assert "Prevalent Wind Pung" not in names


def test_prevalent_wind_pung():
    ctx = GameContext(
        seat_wind=Honor.WEST, prevalent_wind=Honor.EAST,
        win_method=WinMethod.DISCARD, is_concealed=False,
    )
    fan = score([
        "1z", "1z", "1z",
        "4p", "5p", "6p",
        "2s", "3s", "4s",
        "5s", "6s", "7s",
        "9m", "9m",
    ], ctx)
    names = [p["name"] for p in fan["patterns"]]
    assert "Prevalent Wind Pung" in names
    assert "Seat Wind Pung" not in names


def test_double_wind_pung_counts_twice():
    ctx = GameContext(
        seat_wind=Honor.EAST, prevalent_wind=Honor.EAST,
        win_method=WinMethod.DISCARD, is_concealed=False,
    )
    fan = score([
        "1z", "1z", "1z",
        "4p", "5p", "6p",
        "2s", "3s", "4s",
        "5s", "6s", "7s",
        "9m", "9m",
    ], ctx)
    names = [p["name"] for p in fan["patterns"]]
    assert "Prevalent Wind Pung" in names
    assert "Seat Wind Pung" in names


def test_self_drawn_bonus():
    ctx = GameContext(
        seat_wind=Honor.SOUTH, prevalent_wind=Honor.EAST,
        win_method=WinMethod.SELF_DRAW, is_concealed=True,
    )
    fan = score([
        "1m", "2m", "3m",
        "4p", "5p", "6p",
        "2s", "3s", "4s",
        "5s", "6s", "7s",
        "9m", "9m",
    ], ctx)
    names = [p["name"] for p in fan["patterns"]]
    assert "Self-Drawn (Zimo)" in names
    assert "All Chows (Ping Hu)" in names


def test_fully_concealed_bonus_only_on_discard_win():
    ctx = GameContext(
        seat_wind=Honor.SOUTH, prevalent_wind=Honor.EAST,
        win_method=WinMethod.DISCARD, is_concealed=True,
    )
    fan = score([
        "1m", "2m", "3m",
        "4p", "5p", "6p",
        "2s", "3s", "4s",
        "5s", "6s", "7s",
        "9m", "9m",
    ], ctx)
    names = [p["name"] for p in fan["patterns"]]
    assert "Fully Concealed Hand" in names
    assert "Self-Drawn (Zimo)" not in names


def test_all_terminals_and_honors():
    # every meld is a pung of a terminal or honor tile — the only way this
    # pattern can be satisfied (chows are structurally excluded, since no
    # chow can consist purely of terminal values)
    ctx = GameContext(
        seat_wind=Honor.SOUTH, prevalent_wind=Honor.EAST,
        win_method=WinMethod.DISCARD, is_concealed=False,
    )
    fan = score([
        "1m", "1m", "1m",
        "9p", "9p", "9p",
        "1z", "1z", "1z",
        "9s", "9s", "9s",
        "7z", "7z",
    ], ctx)
    names = [p["name"] for p in fan["patterns"]]
    assert "All Terminals and Honors" in names


def test_limit_hand_ignores_context_fan():
    ctx = GameContext(
        seat_wind=Honor.EAST, prevalent_wind=Honor.EAST,
        win_method=WinMethod.SELF_DRAW, is_concealed=True,
    )
    fan = score([
        "5z", "5z", "5z",
        "6z", "6z", "6z",
        "7z", "7z", "7z",
        "1m", "2m", "3m",
        "9s", "9s",
    ], ctx)
    assert fan["total_fan"] == 13
