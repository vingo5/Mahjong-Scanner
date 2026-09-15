# 🀄 MahjongScanner

An iOS app that uses the iPhone camera and an on-device CoreML vision model to
identify a physical Mahjong hand in real time, validate winning hand structure,
and calculate score using Hong Kong Mahjong scoring rules — with a modular
architecture designed to support additional rulesets (Riichi/Japanese,
Taiwanese 16-Tile) in the future.

## Demo

![Demo](docs/demo.gif)
<!-- Added in Phase 5 -->

## Features

- 📷 Real-time tile detection via on-device CoreML object detection
- ✅ Deterministic winning-hand validation (4 Melds + Pair, Seven Pairs, Thirteen Orphans)
- 🧮 Full Hong Kong Fan scoring engine (Chicken Hand → Limit Hands)
- 🀄 Handles Prevalent/Seat Wind, Self-Draw vs. Discard win, Bonus Flowers
- ✋ Manual override UI for correcting misidentified tiles
- 🧩 Modular `RuleSet` architecture for future scoring systems

## Architecture

| Layer | Tech |
|---|---|
| UI | SwiftUI |
| Camera capture | AVFoundation |
| Tile detection | CoreML (YOLOv8-derived object detector) |
| Scoring engine | Swift, ported from a Python-validated reference implementation |
| Model training | Python, Ultralytics YOLOv8 → coremltools export |

See [docs/architecture.md](docs/architecture.md) for the full system diagram and
[docs/scoring-rules-hk.md](docs/scoring-rules-hk.md) for the scoring rules
reference this engine implements.

## Project Structure

See the repository tree — `ios/` for the SwiftUI app, `ml/` for dataset prep
and model training, `scoring-engine-python/` for the reference scoring
implementation and its test suite.

## Status

🚧 Under active development. Build log / phases:

- [x] Phase 1 — Repo architecture & version control
- [ ] Phase 2 — CV tile recognition pipeline
- [ ] Phase 3 — HK scoring engine
- [ ] Phase 4 — SwiftUI camera app
- [ ] Phase 5 — Testing & demo

## Running Locally

_Instructions added as each phase is completed._

## License

MIT — see [LICENSE](LICENSE)
