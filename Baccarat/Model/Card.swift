//
//  Card.swift
//  Baccarat
//
//  Created by Chris Gray on 6/26/21.
//

import Foundation

struct Card {
    enum Suit: String, CaseIterable {
        case spades, diamonds, hearts, clubs
    }

    enum Rank: CaseIterable {
        static var allCases: [Card.Rank] = [
            .two(2),
            .three(3),
            .four(4),
            .five(5),
            .six(6),
            .seven(7),
            .eight(8),
            .nine(9),
            .ten(10),
            .jack(10),
            .queen(10),
            .king(10),
            .ace(1)
        ]

        case two(Int)
        case three(Int)
        case four(Int)
        case five(Int)
        case six(Int)
        case seven(Int)
        case eight(Int)
        case nine(Int)
        case ten(Int)
        case jack(Int)
        case queen(Int)
        case king(Int)
        case ace(Int)

        var value: Int {
            switch self {
            case .two(let int),
                 .three(let int),
                 .four(let int),
                 .five(let int),
                 .six(let int),
                 .seven(let int),
                 .eight(let int),
                 .nine(let int),
                 .ten(let int),
                 .jack(let int),
                 .queen(let int),
                 .king(let int),
                 .ace(let int):
                    return int
            }
        }
    }

    var rank: Rank
    var suit: Suit
    var value: Int {
        return rank.value
    }
}

extension Card: CustomStringConvertible {
    var description: String {
        "\(self.rank) of \(self.suit)"
    }
}
