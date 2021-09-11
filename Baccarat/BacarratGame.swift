//
//  BacarratGame.swift
//  Baccarat
//
//  Created by Chris Gray on 6/26/21.
//

import UIKit

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
    private(set) var totalPlayer = 0
    private(set) var totalBanker = 0
    private(set) var totalTie = 0
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
    weak var viewController: ViewController?
    private var playerNumbers: [Int] = []
    private var bankerNumbers: [Int] = []
    private var tieNumbers: [Int] = []

    var averagePlayer: Double {
        Double(totalPlayer) / Double(shoes)
    }

    var averageBanker: Double {
        Double(totalBanker) / Double(shoes)
    }

    var averageTie: Double {
        Double(totalTie) / Double(shoes)
    }

    enum Bet {
        case player, banker, tie
    }

    func getStandardDeviation(for bet: Bet) -> Double {
        var array: [Int]
        var average: Double
        switch bet {
        case .player:
            array = playerNumbers
            average = averagePlayer
        case .banker:
            array = bankerNumbers
            average = averageBanker
        case .tie:
            array = tieNumbers
            average = averageTie
        }
        var sum = 0.0
        array.forEach {
            sum += pow(Double($0) - average, 2)
        }
        return sum / Double(array.count - 1)
    }

    var workItem: DispatchWorkItem!

    func runAsync() {
        workItem = DispatchWorkItem {
            self.run()
        }
        DispatchQueue.global().async(execute: workItem)
    }

    func run() {
        resetStats()
        simulating = true
        for _ in 0..<shoes {
            guard !workItem.isCancelled else {
                break
            }
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

        DispatchQueue.main.async {
            self.viewController?.done()
        }
    }

    private func resetStats() {
        totalPlayer = 0
        totalBanker = 0
        totalTie = 0
        numberOfShoesBetOn = 0
        totalRoundsPlayedInEntirety = 0
        totalBetsMadeInEntirety = 0
        bankrollHit3Percent = false
        newBankroll = betManager.bankroll
    }

    private func runSimulations() {
        resetShoe()
        oneShoe()
        print("bankroll: \(betManager.bankroll)")
        playerNumbers.append(totalPlayerForShoe)
        bankerNumbers.append(totalBankerForShoe)
        tieNumbers.append(totalTieForShoe)
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
        guard totalRoundsPlayedForShoe >= roundsBeforeEntering else {
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
    }

    private func makeBet() {
        var bet = mainBet
        if betManager.bankroll > newBankroll * (1 + percentIncreaseBet/100) {
            newBankroll = betManager.bankroll
            bet = betAfterWinning
        } else if betManager.bankroll < newBankroll * (1 - percentDecreaseBet/100) {
            bet = betAfterLosing
        }
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
