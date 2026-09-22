from mahjong_scoring.tile import parse_hand
from mahjong_scoring.hand_validator import validate_winning_hand
from mahjong_scoring.fan_calculator import calculate_fan


def score(tiles_str):
    hand = parse_hand(tiles_str)
    result = validate_winning_hand(hand)
    assert result["is_valid"], f"hand should be valid: {tiles_str}"
    return calculate_fan(hand, result["structures"])


def test_chicken_hand():
    # all chows, mixed suits, no honors, no special pattern — 0 fan
    fan = score([
        "1m", "2m", "3m",
        "4p", "5p", "6p",
        "2s", "3s", "4s",
        "5s", "6s", "7s",
        "9m", "9m",
    ])
    assert fan["total_fan"] == 0
    assert fan["patterns"] == []


def test_all_pungs():
    fan = score([
        "1m", "1m", "1m",
        "5p", "5p", "5p",
        "7s", "7s", "7s",
        "3z", "3z", "3z",
        "9m", "9m",
    ])
    names = [p["name"] for p in fan["patterns"]]
    assert "All Pungs (Toitoi)" in names
    assert fan["total_fan"] == 3


def test_half_flush():
    fan = score([
        "1m", "2m", "3m",
        "4m", "5m", "6m",
        "7m", "8m", "9m",
        "1z", "1z", "1z",
        "2z", "2z",
    ])
    names = [p["name"] for p in fan["patterns"]]
    assert "Half Flush (Mixed One Suit)" in names


def test_full_flush_supersedes_half_flush():
    fan = score([
        "1m", "2m", "3m",
        "4m", "5m", "6m",
        "7m", "8m", "9m",
        "2m", "2m", "2m",
        "5m", "5m",
    ])
    names = [p["name"] for p in fan["patterns"]]
    assert "Full Flush (Pure One Suit)" in names
    assert "Half Flush (Mixed One Suit)" not in names


def test_small_three_dragons_no_double_count():
    # two dragon pungs (5z, 6z) + dragon pair (7z)
    fan = score([
        "1m", "2m", "3m",
        "4p", "5p", "6p",
        "5z", "5z", "5z",
        "6z", "6z", "6z",
        "7z", "7z",
    ])
    names = [p["name"] for p in fan["patterns"]]
    assert "Small Three Dragons" in names
    assert not any("Dragon Pung" in n for n in names)  # not double-counted
    assert fan["total_fan"] == 5


def test_big_three_dragons_is_limit():
    fan = score([
        "5z", "5z", "5z",
        "6z", "6z", "6z",
        "7z", "7z", "7z",
        "1m", "2m", "3m",
        "9s", "9s",
    ])
    assert fan["total_fan"] == 13
    assert fan["patterns"][0]["name"] == "Big Three Dragons"
    assert fan["patterns"][0]["is_limit"]


def test_all_honors_is_limit():
    fan = score([
        "1z", "1z", "1z",
        "2z", "2z", "2z",
        "5z", "5z", "5z",
        "6z", "6z", "6z",
        "7z", "7z",
    ])
    assert fan["total_fan"] == 13
    assert fan["patterns"][0]["name"] == "All Honors"


def test_seven_pairs_base_fan():
    fan = score([
        "1m", "1m", "3m", "3m", "5p", "5p", "7p",
        "7p", "9s", "9s", "1z", "1z", "5z", "5z",
    ])
    names = [p["name"] for p in fan["patterns"]]
    assert "Seven Pairs" in names
    assert fan["total_fan"] == 4


def test_thirteen_orphans_is_limit():
    fan = score([
        "1m", "9m", "1p", "9p", "1s", "9s",
        "1z", "2z", "3z", "4z", "5z", "6z", "7z", "1z",
    ])
    assert fan["total_fan"] == 13
    assert fan["patterns"][0]["name"] == "Thirteen Orphans"
