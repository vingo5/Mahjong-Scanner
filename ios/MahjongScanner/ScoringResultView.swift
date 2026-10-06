import SwiftUI

struct ScoringResultView: View {
    let detections: [Detection]
    let onRetake: () -> Void

    @State private var seatWind: Honor = .east
    @State private var prevalentWind: Honor = .east
    @State private var winMethod: WinMethod = .discard
    @State private var isConcealed: Bool = true
    @State private var hasScored = false

    @State private var isValid = false
    @State private var invalidReason: String? = nil
    @State private var patterns: [FanPattern] = []
    @State private var totalFan = 0

    private let honorNames: [Honor: String] = [
        .east: "East", .south: "South", .west: "West", .north: "North"
    ]

    var body: some View {
        VStack(spacing: 20) {
            if !hasScored {
                contextForm
            } else {
                resultView
            }
        }
        .padding()
    }

    private var contextForm: some View {
        VStack(spacing: 20) {
            Text("Hand Context")
                .font(.title2.bold())
                .padding(.top, 40)

            Form {
                Picker("Seat Wind", selection: $seatWind) {
                    ForEach([Honor.east, .south, .west, .north], id: \.self) { h in
                        Text(honorNames[h] ?? "").tag(h)
                    }
                }
                Picker("Prevalent Wind", selection: $prevalentWind) {
                    ForEach([Honor.east, .south, .west, .north], id: \.self) { h in
                        Text(honorNames[h] ?? "").tag(h)
                    }
                }
                Picker("Win Method", selection: $winMethod) {
                    Text("Self-Drawn (Zimo)").tag(WinMethod.selfDraw)
                    Text("Won off Discard").tag(WinMethod.discard)
                }
                Toggle("Fully Concealed Hand", isOn: $isConcealed)
            }
            .frame(height: 260)

            Button(action: calculateScore) {
                Text("Calculate Score")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Button(action: onRetake) {
                Text("Retake")
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            if isValid {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.green)
                Text("Valid Winning Hand")
                    .font(.title2.bold())

                Text("\(totalFan) Fan")
                    .font(.system(size: 40, weight: .bold))
                    .padding(.top, 4)

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(patterns.indices, id: \.self) { i in
                            HStack {
                                Text(patterns[i].name)
                                Spacer()
                                Text(patterns[i].isLimit ? "LIMIT" : "+\(patterns[i].fan)")
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.red)
                Text("Not a Valid Winning Hand")
                    .font(.title2.bold())
                if let reason = invalidReason {
                    Text(reason)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            Spacer()

            Button(action: onRetake) {
                Text("Scan Another Hand")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }

    private func calculateScore() {
        let tiles = detections.compactMap { Tile.from($0.label) }

        guard tiles.count == 14 else {
            isValid = false
            invalidReason = "Detected \(tiles.count) tiles — a winning hand needs exactly 14. Retake and check for missed or extra detections."
            hasScored = true
            return
        }

        let (valid, structures) = HandValidator.validateWinningHand(tiles)

        guard valid else {
            isValid = false
            invalidReason = "These 14 tiles don't form a legal winning hand (4 melds + pair, seven pairs, or thirteen orphans)."
            hasScored = true
            return
        }

        let ctx = GameContext(
            seatWind: seatWind,
            prevalentWind: prevalentWind,
            winMethod: winMethod,
            isConcealed: isConcealed
        )
        let result = FanCalculator.calculateFan(tiles, structures, ctx)

        isValid = true
        patterns = result.patterns
        totalFan = result.totalFan
        hasScored = true
    }
}
