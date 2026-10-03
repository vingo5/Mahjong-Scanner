import SwiftUI

struct CapturedHandView: View {
    let tiles: [Detection]
    let onRetake: () -> Void
    let onConfirm: () -> Void

    private var sortedTiles: [Detection] {
        tiles.sorted { a, b in
            let (suitA, valueA) = parse(a.label)
            let (suitB, valueB) = parse(b.label)
            if suitA != suitB { return suitOrder(suitA) < suitOrder(suitB) }
            return valueA < valueB
        }
    }

    private func parse(_ label: String) -> (String, Int) {
        guard let suit = label.last, let value = Int(label.dropLast()) else {
            return ("?", 0)
        }
        return (String(suit), value)
    }

    private func suitOrder(_ suit: String) -> Int {
        switch suit {
        case "m": return 0
        case "p": return 1
        case "s": return 2
        case "z": return 3
        default: return 4
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Captured Hand")
                .font(.title2.bold())
                .padding(.top, 40)

            Text("\(tiles.count) tiles detected")
                .foregroundColor(.secondary)

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    ForEach(sortedTiles) { tile in
                        VStack(spacing: 4) {
                            Text(tile.label)
                                .font(.headline)
                            Text("\(Int(tile.confidence * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 60, height: 60)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }

            if tiles.count != 13 && tiles.count != 14 {
                Text("⚠️ Expected 13 or 14 tiles for a valid hand — check for missed or extra detections")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            HStack(spacing: 16) {
                Button(action: onRetake) {
                    Text("Retake")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                }

                Button(action: onConfirm) {
                    Text("Confirm Hand")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
    }
}
