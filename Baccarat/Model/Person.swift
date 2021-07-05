//
//  Person.swift
//  Baccarat
//
//  Created by Chris Gray on 6/26/21.
//

import Foundation

struct Person {
    var cards: [Card] = []

    var total: Int {
        var total = cards.reduce(0) {
            result, card in result + card.value
        }
        while total >= 10 {
            total -= 10
        }
        return total
    }
}

extension Sequence where Element: Numeric {
    /// Returns the sum of all elements in the collection
    func sum() -> Element { return reduce(0, +) }
}
