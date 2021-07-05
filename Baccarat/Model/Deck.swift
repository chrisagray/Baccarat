//
//  Deck.swift
//  Baccarat
//
//  Created by Chris Gray on 6/26/21.
//

import GameplayKit

struct Deck {
    var cards: [Card]

    init() {
        cards = Card.Rank.allCases.flatMap { rank in
            Card.Suit.allCases.map { suit in
                Card(rank: rank, suit: suit)
            }
        }
        shuffle()
    }

    mutating func shuffle() {
        cards = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: cards) as! [Card]
    }

    mutating func draw() -> Card {
        return cards.removeFirst()
    }
}

extension Deck: CustomStringConvertible {
    var description: String {
        var string = ""
        for card in cards {
            string.append("\(card.description)\n")
        }
        return string
    }
}
