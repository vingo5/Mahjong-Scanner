import Foundation

struct WinningStructure {
    let type: String
    let decompositions: [[Meld]]
}

enum HandValidator {

    static func validateWinningHand(_ tiles: [Tile]) -> (isValid: Bool, structures: [WinningStructure]) {
        var structures: [WinningStructure] = []

        if let standard = standardWinningHand(tiles) {
            structures.append(WinningStructure(type: "standard", decompositions: standard))
        }
        if isSevenPairs(tiles) {
            structures.append(WinningStructure(type: "seven_pairs", decompositions: []))
        }
        if isThirteenOrphans(tiles) {
            structures.append(WinningStructure(type: "thirteen_orphans", decompositions: []))
        }

        return (!structures.isEmpty, structures)
    }

    static func standardWinningHand(_ tiles: [Tile]) -> [[Meld]]? {
        guard tiles.count == 14 else { return nil }

        var counts: [Tile: Int] = [:]
        for t in tiles { counts[t, default: 0] += 1 }

        var solutions: [[Meld]] = []
        let pairCandidates = Set(counts.filter { $0.value >= 2 }.keys)

        for pairTile in pairCandidates {
            var remaining = counts
            remaining[pairTile]! -= 2
            if remaining[pairTile] == 0 { remaining.removeValue(forKey: pairTile) }

            var melds: [Meld] = []
            if decomposeMelds(&remaining, &melds, targetMelds: 4) {
                let pair = Meld(type: .pair, tiles: [pairTile, pairTile])
                solutions.append(melds + [pair])
            }
        }

        return solutions.isEmpty ? nil : solutions
    }

    private static func decomposeMelds(_ counts: inout [Tile: Int], _ found: inout [Meld], targetMelds: Int) -> Bool {
        if found.count == targetMelds {
            return counts.values.reduce(0, +) == 0
        }
        guard !counts.isEmpty else { return false }

        let tile = counts.keys.min { a, b in
            (a.suit.rawValue, a.value) < (b.suit.rawValue, b.value)
        }!

        if counts[tile]! >= 3 {
            counts[tile]! -= 3
            let removed = counts[tile] == 0
            if removed { counts.removeValue(forKey: tile) }

            found.append(Meld(type: .pung, tiles: [tile, tile, tile]))
            if decomposeMelds(&counts, &found, targetMelds: targetMelds) { return true }
            found.removeLast()

            counts[tile] = removed ? 3 : (counts[tile] ?? 0) + 3
        }

        if tile.suit != .honor && tile.value <= 7 {
            let t2 = Tile(suit: tile.suit, value: tile.value + 1)
            let t3 = Tile(suit: tile.suit, value: tile.value + 2)
            if (counts[t2] ?? 0) >= 1 && (counts[t3] ?? 0) >= 1 {
                counts[tile]! -= 1
                counts[t2]! -= 1
                counts[t3]! -= 1
                for t in [tile, t2, t3] where counts[t] == 0 { counts.removeValue(forKey: t) }

                found.append(Meld(type: .chow, tiles: [tile, t2, t3]))
                if decomposeMelds(&counts, &found, targetMelds: targetMelds) { return true }
                found.removeLast()

                counts[tile] = (counts[tile] ?? 0) + 1
                counts[t2] = (counts[t2] ?? 0) + 1
                counts[t3] = (counts[t3] ?? 0) + 1
            }
        }

        return false
    }

    static func isSevenPairs(_ tiles: [Tile]) -> Bool {
        guard tiles.count == 14 else { return false }
        var counts: [Tile: Int] = [:]
        for t in tiles { counts[t, default: 0] += 1 }
        return counts.count == 7 && counts.values.allSatisfy { $0 == 2 }
    }

    static let thirteenOrphanTiles: Set<Tile> = [
        Tile(suit: .man, value: 1), Tile(suit: .man, value: 9),
        Tile(suit: .pin, value: 1), Tile(suit: .pin, value: 9),
        Tile(suit: .sou, value: 1), Tile(suit: .sou, value: 9),
        Tile(suit: .honor, value: 1), Tile(suit: .honor, value: 2),
        Tile(suit: .honor, value: 3), Tile(suit: .honor, value: 4),
        Tile(suit: .honor, value: 5), Tile(suit: .honor, value: 6),
        Tile(suit: .honor, value: 7),
    ]

    static func isThirteenOrphans(_ tiles: [Tile]) -> Bool {
        guard tiles.count == 14 else { return false }
        var counts: [Tile: Int] = [:]
        for t in tiles { counts[t, default: 0] += 1 }
        guard Set(counts.keys) == thirteenOrphanTiles else { return false }
        let pairCount = counts.values.filter { $0 == 2 }.count
        let singleCount = counts.values.filter { $0 == 1 }.count
        return pairCount == 1 && singleCount == 12
    }
}
