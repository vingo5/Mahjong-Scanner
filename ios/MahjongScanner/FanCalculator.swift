import Foundation

struct FanPattern {
    let name: String
    let fan: Int
    let isLimit: Bool
}

enum WinMethod {
    case selfDraw
    case discard
}

struct GameContext {
    let seatWind: Honor
    let prevalentWind: Honor
    let winMethod: WinMethod
    let isConcealed: Bool
}

enum FanCalculator {
    static let limitFan = 13

    // MARK: - Composition-based (batch 1)

    private static func suitsUsed(_ tiles: [Tile]) -> Set<Suit> {
        Set(tiles.map { $0.suit })
    }

    private static func dragonPungs(_ decomposition: [Meld]) -> [Meld] {
        decomposition.filter {
            ($0.type == .pung || $0.type == .kong) && $0.tiles[0].isDragon
        }
    }

    static func allHonors(_ tiles: [Tile]) -> Bool {
        tiles.allSatisfy { $0.isHonor }
    }

    static func bigThreeDragons(_ decomposition: [Meld]) -> Bool {
        let pungs = dragonPungs(decomposition)
        let values = Set(pungs.map { $0.tiles[0].value })
        return pungs.count == 3 && values == [5, 6, 7]
    }

    static func smallThreeDragons(_ decomposition: [Meld]) -> Bool {
        let pungs = dragonPungs(decomposition)
        guard let pair = decomposition.first(where: { $0.type == .pair }) else { return false }
        return pungs.count == 2 && pair.tiles[0].isDragon
    }

    static func allPungs(_ decomposition: [Meld]) -> Bool {
        let nonPair = decomposition.filter { $0.type != .pair }
        return nonPair.count == 4 && nonPair.allSatisfy { $0.type == .pung || $0.type == .kong }
    }

    static func fullFlush(_ tiles: [Tile]) -> Bool {
        let suits = suitsUsed(tiles)
        return suits.count == 1 && !suits.contains(.honor)
    }

    static func halfFlush(_ tiles: [Tile]) -> Bool {
        let suits = suitsUsed(tiles)
        let nonHonor = suits.subtracting([.honor])
        return nonHonor.count == 1 && suits.contains(.honor)
    }

    static func scoreStandardDecomposition(_ tiles: [Tile], _ decomposition: [Meld]) -> [FanPattern] {
        if allHonors(tiles) {
            return [FanPattern(name: "All Honors", fan: limitFan, isLimit: true)]
        }
        if bigThreeDragons(decomposition) {
            return [FanPattern(name: "Big Three Dragons", fan: limitFan, isLimit: true)]
        }

        var patterns: [FanPattern] = []

        if allPungs(decomposition) {
            patterns.append(FanPattern(name: "All Pungs (Toitoi)", fan: 3, isLimit: false))
        }

        if fullFlush(tiles) {
            patterns.append(FanPattern(name: "Full Flush (Pure One Suit)", fan: 6, isLimit: false))
        } else if halfFlush(tiles) {
            patterns.append(FanPattern(name: "Half Flush (Mixed One Suit)", fan: 3, isLimit: false))
        }

        if smallThreeDragons(decomposition) {
            patterns.append(FanPattern(name: "Small Three Dragons", fan: 5, isLimit: false))
        } else {
            for pung in dragonPungs(decomposition) {
                patterns.append(FanPattern(name: "Dragon Pung", fan: 1, isLimit: false))
            }
        }

        return patterns
    }

    // MARK: - Context-based (batch 2)

    private static func windValue(_ h: Honor) -> Int { h.rawValue }

    static func prevalentWindPung(_ decomposition: [Meld], _ ctx: GameContext) -> Bool {
        decomposition.contains {
            ($0.type == .pung || $0.type == .kong) &&
            $0.tiles[0].isWind &&
            $0.tiles[0].value == windValue(ctx.prevalentWind)
        }
    }

    static func seatWindPung(_ decomposition: [Meld], _ ctx: GameContext) -> Bool {
        decomposition.contains {
            ($0.type == .pung || $0.type == .kong) &&
            $0.tiles[0].isWind &&
            $0.tiles[0].value == windValue(ctx.seatWind)
        }
    }

    static func allChows(_ decomposition: [Meld]) -> Bool {
        let nonPair = decomposition.filter { $0.type != .pair }
        guard let pair = decomposition.first(where: { $0.type == .pair }), nonPair.count == 4 else { return false }
        return nonPair.allSatisfy { $0.type == .chow } && !pair.tiles[0].isHonor
    }

    static func allTerminalsAndHonors(_ tiles: [Tile]) -> Bool {
        guard tiles.allSatisfy({ $0.isTerminal || $0.isHonor }) else { return false }
        return tiles.contains { !$0.isHonor }
    }

    static func pureStraight(_ decomposition: [Meld]) -> Bool {
        let chows = decomposition.filter { $0.type == .chow }
        var bySuit: [Suit: Set<Int>] = [:]
        for c in chows {
            bySuit[c.tiles[0].suit, default: []].insert(c.tiles[0].value)
        }
        return bySuit.values.contains { starts in [1, 4, 7].allSatisfy { starts.contains($0) } }
    }

    static func scoreContextPatterns(_ tiles: [Tile], _ decomposition: [Meld], _ ctx: GameContext) -> [FanPattern] {
        var patterns: [FanPattern] = []

        if allTerminalsAndHonors(tiles) {
            patterns.append(FanPattern(name: "All Terminals and Honors", fan: 10, isLimit: false))
        }
        if pureStraight(decomposition) {
            patterns.append(FanPattern(name: "Pure Straight (1-9)", fan: 3, isLimit: false))
        }
        if prevalentWindPung(decomposition, ctx) {
            patterns.append(FanPattern(name: "Prevalent Wind Pung", fan: 1, isLimit: false))
        }
        if seatWindPung(decomposition, ctx) {
            patterns.append(FanPattern(name: "Seat Wind Pung", fan: 1, isLimit: false))
        }
        if allChows(decomposition) {
            patterns.append(FanPattern(name: "All Chows (Ping Hu)", fan: 1, isLimit: false))
        }
        if ctx.winMethod == .selfDraw {
            patterns.append(FanPattern(name: "Self-Drawn (Zimo)", fan: 1, isLimit: false))
        }
        if ctx.isConcealed && ctx.winMethod == .discard {
            patterns.append(FanPattern(name: "Fully Concealed Hand", fan: 1, isLimit: false))
        }

        return patterns
    }

    // MARK: - Top-level entry point

    static func calculateFan(_ tiles: [Tile], _ structures: [WinningStructure], _ ctx: GameContext) -> (patterns: [FanPattern], totalFan: Int) {
        var best: [FanPattern] = []
        var bestTotal = -1

        for structure in structures {
            switch structure.type {
            case "standard":
                for decomposition in structure.decompositions {
                    let batch1 = scoreStandardDecomposition(tiles, decomposition)
                    var patterns: [FanPattern]
                    var total: Int

                    if batch1.contains(where: { $0.isLimit }) {
                        total = limitFan
                        patterns = batch1
                    } else {
                        let batch2 = scoreContextPatterns(tiles, decomposition, ctx)
                        patterns = batch1 + batch2
                        total = patterns.reduce(0) { $0 + $1.fan }
                    }

                    if total > bestTotal {
                        bestTotal = total
                        best = patterns
                    }
                }

            case "seven_pairs":
                var patterns = [FanPattern(name: "Seven Pairs", fan: 4, isLimit: false)]
                if fullFlush(tiles) {
                    patterns.append(FanPattern(name: "Full Flush (Pure One Suit)", fan: 6, isLimit: false))
                } else if halfFlush(tiles) {
                    patterns.append(FanPattern(name: "Half Flush (Mixed One Suit)", fan: 3, isLimit: false))
                }
                if ctx.winMethod == .selfDraw {
                    patterns.append(FanPattern(name: "Self-Drawn (Zimo)", fan: 1, isLimit: false))
                }
                let total = patterns.reduce(0) { $0 + $1.fan }
                if total > bestTotal {
                    bestTotal = total
                    best = patterns
                }

            case "thirteen_orphans":
                if limitFan > bestTotal {
                    bestTotal = limitFan
                    best = [FanPattern(name: "Thirteen Orphans", fan: limitFan, isLimit: true)]
                }

            default:
                break
            }
        }

        return (best, max(bestTotal, 0))
    }
}
