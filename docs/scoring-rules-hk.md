
## Tile Class Naming Convention

Using standard Mahjong shorthand (matches Roboflow project-xv49e/mahjong-x5dzz dataset):
- `1m`-`9m` — Characters/Man (萬)
- `1p`-`9p` — Dots/Pin (筒)
- `1s`-`9s` — Bamboo/Sou (索)
- `1z`-`4z` — Winds: East, South, West, North
- `5z`-`7z` — Dragons: White, Green, Red
- Bonus tiles (flowers/seasons): not covered by CV model v1 — entered manually in-app

34 classes total, 0-indexed 0-33 in data.yaml order.
