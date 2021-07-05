//
//  BacarratGame.swift
//  Baccarat
//
//  Created by Chris Gray on 6/26/21.
//

import Foundation

class BacarratGame {
    // MARK: Properties

    var shoes = 1000
    var startMultiplier = 5.0
    var endMultiplier = 3.0
    var percentIncreaseBet = 1.0
    var percentDecreaseBet = 1.0
    var mainBet = 100
    var betAfterWinning = 50
    var betAfterLosing = 1000
    var roundsBeforeEntering = 20

    // MARK: Private properties

    private var shoe = Shoe(decks: [])
    private var player = Person()
    private var banker = Person()
    private var totalPlayer = 0
    private var totalBanker = 0
    private var totalTie = 0
    private var totalPlayerForShoe = 0
    private var totalBankerForShoe = 0
    private var totalTieForShoe = 0
    private(set) var betManager = BetManager()
    private var totalBetsMade = 0 {
        didSet {
            if totalBetsMade == 10 {
                inA10BetStreak = false
                totalBetsMade = 0
            }
        }
    }
    private var inA10BetStreak = false
    private var currentlyBettingOn: Result!
    private var totalRoundsPlayedForShoe = 0
    private var totalBetsMadeInEntirety = 0

    private var totalRoundsPlayedInEntirety = 0
    private var betOnShoe = false
    private(set) var numberOfShoesBetOn = 0
    private var bankrollHit3Percent = false
    private lazy var newBankroll = betManager.bankroll
    var simulating = false

    func run(group: DispatchGroup) {
        simulating = true
        for _ in 0..<shoes {
            runSimulations()
        }
        simulating = false

        print("total banker: \(totalBanker)")
        print("total player: \(totalPlayer)")
        print("total tie: \(totalTie)")
        print("total bets: \(totalBetsMadeInEntirety)")
        print("rounds played in all: \(totalRoundsPlayedInEntirety)")
        print("end bankroll: \(betManager.bankroll)")
        print("number of shoes bet on: \(numberOfShoesBetOn)")

        group.leave()
    }

    private func runSimulations() {
        resetShoe()
        oneShoe()
        print("bankroll: \(betManager.bankroll)")
        totalPlayer += totalPlayerForShoe
        totalBanker += totalBankerForShoe
        totalTie += totalTieForShoe
    }

    private func oneShoe() {
        while shoe.totalCards > 16 {
            oneHand()
            totalRoundsPlayedInEntirety += 1
        }
    }

    private func resetShoe() {
        shoe.decks = [Deck(), Deck(), Deck(), Deck(), Deck(), Deck(), Deck(), Deck()]
        player.cards.removeAll()
        banker.cards.removeAll()
        totalPlayerForShoe = 0
        totalBankerForShoe = 0
        totalTieForShoe = 0
        totalRoundsPlayedForShoe = 0
        if betOnShoe {
            numberOfShoesBetOn += 1
        }
        betOnShoe = false
    }

    private func oneHand() {
        defer {
            totalRoundsPlayedForShoe += 1
        }

        makeBets()
        player.cards = [shoe.draw(), shoe.draw()]
        banker.cards = [shoe.draw(), shoe.draw()]

        // Natural
        guard !(player.total == 8 || player.total == 9 || banker.total == 8 || banker.total == 9) else {
            return calculateResult()
        }

        // third card
        if player.total <= 5 {
            drawThirdCard(for: &player)
            if bankerNeedsToDrawBasedOnPlayersThirdCard() {
                drawThirdCard(for: &banker)
            }
        } else {
            guard player.total == 6 || player.total == 7 else {
                fatalError("should not get here")
            }
            if banker.total <= 5 {
                drawThirdCard(for: &banker)
            }
        }

        calculateResult()
    }

    private func makeBets() {
//        betManager.makeBet(amount: 100, for: .player)

        // 10 bets

//        if inA10BetStreak {
//            makeBet()
//        } else {
//            // At least x rounds played before betting.
//            guard totalRoundsPlayedForShoe > 40 else {
//                return
//            }
//            // Need to be able to make 10 bets
//            if shoe.totalCards >= 50 {
//                let multiplier = betOnShoe ? 2 : 3
//                let betOnBanker = totalPlayerForShoe >= totalBankerForShoe * multiplier
//                let betOnPlayer = totalBankerForShoe >= totalPlayerForShoe * multiplier
//                if betOnPlayer || betOnBanker {
//                    inA10BetStreak = true
//                    betOnShoe = true
//                    currentlyBettingOn = betOnPlayer ? .player : .banker
//                    makeBet()
//                }
//            }
//        }

        guard totalRoundsPlayedForShoe >= 10 else {
            return
        }
        let multiplier: Double = betOnShoe ? endMultiplier : startMultiplier
        let betOnBanker = Double(totalPlayerForShoe) >= Double(totalBankerForShoe) * multiplier
        let betOnPlayer = Double(totalBankerForShoe) >= (Double(totalPlayerForShoe) * multiplier)
        if betOnPlayer || betOnBanker {
            betOnShoe = true
            currentlyBettingOn = betOnPlayer ? .player : .banker
            makeBet()
        }

        // Need to be able to make 10 bets
//        if shoe.totalCards >= 50 {
//
//        }
    }

    private func makeBet() {
//        let multiplier = currentlyBettingOn == .banker ? totalPlayerForShoe / totalBankerForShoe : totalBankerForShoe / totalPlayerForShoe
//        let bet: Double = 100 //multiplier == 3 ? 100 : multiplier == 4 ? 1000 : multiplier >= 5 ? 10000 : 0
        var bet = mainBet
        if betManager.bankroll > newBankroll * (1 + percentIncreaseBet/100) {
            newBankroll = betManager.bankroll
            bet = betAfterWinning
        } else if betManager.bankroll < newBankroll * (1 - percentDecreaseBet/100) {
            bet = betAfterLosing
        }
//        if betManager.bankroll > 102000 {
//            bankrollGreaterThan102k = true
//        }
//        if bankrollGreaterThan102k {
//            bet = betManager.bankroll < 102000 ? 1000 : betManager.bankroll > 105000 ? 50 : 100
//        } else {
//            bet = betManager.bankroll < 99000 ? 1000 : 100 //betManager.bankroll > 101000 ? 50 : 100
//        }
        betManager.makeBet(amount: bet, for: currentlyBettingOn)
        totalBetsMade += 1
        totalBetsMadeInEntirety += 1
    }

    private func drawThirdCard(for person: inout Person) {
        let card = shoe.draw()
        person.cards.append(card)
    }

    private func bankerNeedsToDrawBasedOnPlayersThirdCard() -> Bool {
        let playersThirdCard = player.cards.last!.rank.value
        // Note: this rank.value is an Int, not a "person.total"
        switch banker.total {
        case 7:
            return false
        case 6:
            return playersThirdCard == 7 || playersThirdCard == 6
        case 5:
            return playersThirdCard == 7 || playersThirdCard == 6 || playersThirdCard == 5 || playersThirdCard == 4
        case 4:
            return playersThirdCard == 7 || playersThirdCard == 6 || playersThirdCard == 5 || playersThirdCard == 4
                || playersThirdCard == 3 || playersThirdCard == 2
        case 3:
            return playersThirdCard != 8
        case 2, 1, 0:
            return true

        default:
            fatalError("should not get here")
        }
    }

    private func calculateResult() {
        let playerResult = 9 - player.total
        let bankerResult = 9 - banker.total
        let result: Result = playerResult < bankerResult ? .player : bankerResult < playerResult ? .banker : .tie
        switch result {
        case .player:
            totalPlayerForShoe += 1
        case .banker:
            totalBankerForShoe += 1
        case .tie:
            totalTieForShoe += 1
        }

        betManager.winOrLose(result: result)
    }
}
