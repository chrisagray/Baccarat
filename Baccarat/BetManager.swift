//
//  BetManager.swift
//  Baccarat
//
//  Created by Chris Gray on 6/26/21.
//

import Foundation

class BetManager {
    var bankroll = 100_000.0
    private var bet = 0
    private var betOn: Result?

    func makeBet(amount: Int, for result: Result) {
        bet = amount
        betOn = result
    }

    func winOrLose(result: Result) {
        switch (betOn, result) {
        case (.player, .player):
            bankroll += Double(bet)
        case (.player, .banker):
            bankroll -= Double(bet)
        case (.banker, .banker):
            bankroll += Double(bet) * 0.95
        case (.banker, .player):
            bankroll -= Double(bet)
        case (_, .tie):
            break
        default: // Didn't make a bet
            break
        }
        bet = 0
    }
}
