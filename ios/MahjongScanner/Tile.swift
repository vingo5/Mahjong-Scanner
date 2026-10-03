import Foundation

enum Suit: String {
    case man = "m"
    case pin = "p"
    case sou = "s"
    case honor = "z"
}

enum Honor: Int {
    case east = 1, south = 2, west = 3, north = 4
    case whiteDragon = 5, greenDragon = 6, redDragon = 7
}

struct Tile: Hashable {
    let suit: Suit
    let value: Int

    var isHonor: Bool { suit == .honor }
    var isTerminal: Bool { !isHonor && (value == 1 || value == 9) }
    var isWind: Bool { isHonor && value <= 4 }
    var isDragon: Bool { isHonor && value >= 5 }

    static func from(_ label: String) -> Tile? {
        guard let suitChar = label.last,
              let suit = Suit(rawValue: String(suitChar)),
              let value = Int(label.dropLast())
        else { return nil }
        return Tile(suit: suit, value: value)
    }
}

enum MeldType {
    case chow, pung, kong, pair
}

struct Meld {
    let type: MeldType
    let tiles: [Tile]
}
