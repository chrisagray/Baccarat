//
//  Shoe.swift
//  Baccarat
//
//  Created by Chris Gray on 6/26/21.
//

import Foundation

struct Shoe {
    var decks: [Deck]

    mutating func draw() -> Card {
        if decks[0].cards.isEmpty {
            decks.removeFirst()
        }
        return decks[0].draw()
    }

    var totalCards: Int {
        var count = 0
        for deck in decks {
            count += deck.cards.count
        }
        return count
    }
}

extension Shoe: CustomStringConvertible {
    var description: String {
        var string = ""
        for deck in decks {
            string += "\(deck.description)\n"
        }
        return string
    }
}
