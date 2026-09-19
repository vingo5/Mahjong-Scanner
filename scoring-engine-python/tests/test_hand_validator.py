from mahjong_scoring.tile import parse_hand
from mahjong_scoring.hand_validator import validate_winning_hand


def test_simple_standard_hand():
    hand = parse_hand([
        "1m", "2m", "3m",
        "4p", "5p", "6p",
        "7s", "8s", "9s",
        "1z", "1z", "1z",
        "2z", "2z",
    ])
    result = validate_winning_hand(hand)
    assert result["is_valid"]
    assert any(s["type"] == "standard" for s in result["structures"])


def test_seven_pairs():
    hand = parse_hand([
        "1m", "1m", "3m", "3m", "5p", "5p", "7p",
        "7p", "9s", "9s", "1z", "1z", "5z", "5z",
    ])
    result = validate_winning_hand(hand)
    assert result["is_valid"]
    assert any(s["type"] == "seven_pairs" for s in result["structures"])


def test_thirteen_orphans():
    hand = parse_hand([
        "1m", "9m", "1p", "9p", "1s", "9s",
        "1z", "2z", "3z", "4z", "5z", "6z", "7z", "1z",
    ])
    result = validate_winning_hand(hand)
    assert result["is_valid"]
    assert any(s["type"] == "thirteen_orphans" for s in result["structures"])


def test_invalid_hand():
    hand = parse_hand([
        "1m", "3m", "5m", "7p", "9p", "2s",
        "4s", "6s", "1z", "3z", "5z", "7z", "2m", "4m",
    ])
    result = validate_winning_hand(hand)
    assert not result["is_valid"]


def test_wrong_tile_count():
    hand = parse_hand(["1m", "2m", "3m"])
    result = validate_winning_hand(hand)
    assert not result["is_valid"]
