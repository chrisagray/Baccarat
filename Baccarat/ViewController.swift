//
//  ViewController.swift
//  Baccarat
//
//  Created by Chris Gray on 7/5/21.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var baccaratSimLabel: UILabel!
    @IBOutlet weak var simulateButton: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var bankrollTextField: UITextField!
    @IBOutlet weak var shoesTextField: UITextField!
    @IBOutlet weak var startMultiplierTextField: UITextField!
    @IBOutlet weak var endMultiplierTextField: UITextField!
    @IBOutlet weak var percentIncreaseBetTextField: UITextField!
    @IBOutlet weak var percentDecreaseBetTextField: UITextField!
    @IBOutlet weak var mainBetTextField: UITextField!
    @IBOutlet weak var betAfterWinningTextField: UITextField!
    @IBOutlet weak var betAfterLosingTextField: UITextField!
    @IBOutlet weak var roundsBeforeEnteringTextField: UITextField!

    @IBOutlet weak var bankrollLabel: UILabel!
    @IBOutlet weak var numberOfShoesBetOnLabel: UILabel!
    @IBOutlet weak var meanStandardDeviationLabel: UILabel!

    private var keyboardIsShowing = false

    lazy var resultLabels = [
        bankrollLabel,
        numberOfShoesBetOnLabel,
        meanStandardDeviationLabel
    ]

    lazy var allTextFields = [
        bankrollTextField,
        shoesTextField,
        startMultiplierTextField,
        endMultiplierTextField,
        percentIncreaseBetTextField,
        percentDecreaseBetTextField,
        mainBetTextField,
        betAfterWinningTextField,
        betAfterLosingTextField,
        roundsBeforeEnteringTextField
    ]

    var currentlyEditing: UITextField?

    let game = BacarratGame()
    let userDefaults = UserDefaults.standard
    private var isExecuting = false {
        didSet {
            simulateButton.setTitle(isExecuting ? "Stop" : "Run Simulation", for: .normal)
            if isExecuting {
                spinner.startAnimating()
                spinner.isHidden = false
            } else {
                spinner.stopAnimating()
                spinner.isHidden = true
            }
        }
    }

    let bankrollKey = "bankroll"
    let shoesKey = "shoes"
    let startMultiplierKey = "startMultiplier"
    let endMultiplierKey = "endMultiplier"
    let percentIncreaseBetKey = "percentIncreaseBet"
    let percentDecreaseBetKey = "percentDecreaseBet"
    let mainBetKey = "mainBet"
    let betAfterWinningKey = "betAfterWinning"
    let betAfterLosingKey = "betAfterLosing"
    let roundsBeforeEnteringKey = "roundsBeforeEntering"
    let setUserDefaultsKey = "setUserDefaults"

    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.isHidden = true
        getValues()
        allTextFields.forEach {
            $0!.delegate = self
            configureKeyboardToolbar(in: $0!)
        }
        game.viewController = self
        showOrHideResultLabels(hide: true)
    }

    func configureKeyboardToolbar(in textField: UITextField) {
        let bar = UIToolbar()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneButtonTapped))
        bar.items = [flexibleSpace,done]
        bar.sizeToFit()
        textField.inputAccessoryView = bar
    }

    @objc private func doneButtonTapped() {
        currentlyEditing?.resignFirstResponder()
    }

    @IBAction func simulateTapped(_ sender: UIButton) {
        guard !isExecuting else {
            return game.workItem.cancel()
        }
        do {
            try setVariables()
        } catch {
            return showAlert()
        }
        setUserDefaults()
        showOrHideResultLabels(hide: true)
        isExecuting = true
        game.runAsync()
    }

    func done() {
        isExecuting = false
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.maximumFractionDigits = 2
        let bankrollString = formatter.string(from: game.betManager.bankroll as NSNumber)!
        bankrollLabel.text = "End bankroll: \(bankrollString)"
        numberOfShoesBetOnLabel.text = "Number of shoes bet on: \(game.numberOfShoesBetOn)"
        showOrHideResultLabels(hide: false)
        meanStandardDeviationLabel.text = """
        Average player: \(game.averagePlayer)
        Average banker: \(game.averageBanker)
        Average tie: \(game.averageTie)
        Std dev player: \(formatter.string(from: game.getStandardDeviation(for: .player) as NSNumber)!)
        Std dev banker: \(formatter.string(from: game.getStandardDeviation(for: .banker) as NSNumber)!)
        Std dev tie: \(formatter.string(from: game.getStandardDeviation(for: .tie) as NSNumber)!)
        """
    }

    private func setVariables() throws {
        guard let bankroll = Double(bankrollTextField.text ?? ""),
              let shoes = Int(shoesTextField.text ?? ""),
              let startMultiplier = Double(startMultiplierTextField.text ?? ""),
              let endMultiplier = Double(endMultiplierTextField.text ?? ""),
              let percentIncreaseBet = Double(percentIncreaseBetTextField.text ?? ""),
              let percentDecreaseBet = Double(percentDecreaseBetTextField.text ?? ""),
              let mainBet = Int(mainBetTextField.text ?? ""),
              let betAfterWinning = Int(betAfterWinningTextField.text ?? ""),
              let betAfterLosing = Int(betAfterLosingTextField.text ?? ""),
              let roundsBeforeEntering = Int(roundsBeforeEnteringTextField.text ?? "")
              else {
            throw NSError(domain: "", code: -1, userInfo: [:])
        }
        game.betManager.bankroll = bankroll
        game.shoes = shoes
        game.startMultiplier = startMultiplier
        game.endMultiplier = endMultiplier
        game.percentIncreaseBet = percentIncreaseBet
        game.percentDecreaseBet = percentDecreaseBet
        game.mainBet = mainBet
        game.betAfterWinning = betAfterWinning
        game.betAfterLosing = betAfterLosing
        game.roundsBeforeEntering = roundsBeforeEntering
    }

    private func showAlert() {
        let alert = UIAlertController(title: "Invalid values", message: "Please set a value in each text field", preferredStyle: .alert)
        present(alert, animated: true)
    }

    private func getValues() {
        guard userDefaults.bool(forKey: setUserDefaultsKey) else {
            return
        }
        bankrollTextField.text = String(userDefaults.double(forKey: bankrollKey))
        shoesTextField.text = String(userDefaults.integer(forKey: shoesKey))
        startMultiplierTextField.text = String(userDefaults.double(forKey: startMultiplierKey))
        endMultiplierTextField.text = String(userDefaults.double(forKey: endMultiplierKey))
        percentIncreaseBetTextField.text = String(userDefaults.double(forKey: percentIncreaseBetKey))
        percentDecreaseBetTextField.text = String(userDefaults.double(forKey: percentDecreaseBetKey))
        mainBetTextField.text = String(userDefaults.integer(forKey: mainBetKey))
        betAfterWinningTextField.text = String(userDefaults.integer(forKey: betAfterWinningKey))
        betAfterLosingTextField.text = String(userDefaults.integer(forKey: betAfterLosingKey))
        roundsBeforeEnteringTextField.text = String(userDefaults.integer(forKey: roundsBeforeEnteringKey))
    }

    private func setUserDefaults() {
        userDefaults.setValue(true, forKey: setUserDefaultsKey)
        userDefaults.setValue(game.betManager.bankroll, forKey: bankrollKey)
        userDefaults.setValue(game.shoes, forKey: shoesKey)
        userDefaults.setValue(game.startMultiplier, forKey: startMultiplierKey)
        userDefaults.setValue(game.endMultiplier, forKey: endMultiplierKey)
        userDefaults.setValue(game.percentIncreaseBet, forKey: percentIncreaseBetKey)
        userDefaults.setValue(game.percentDecreaseBet, forKey: percentDecreaseBetKey)
        userDefaults.setValue(game.mainBet, forKey: mainBetKey)
        userDefaults.setValue(game.betAfterWinning, forKey: betAfterWinningKey)
        userDefaults.setValue(game.betAfterLosing, forKey: betAfterLosingKey)
        userDefaults.setValue(game.roundsBeforeEntering, forKey: roundsBeforeEnteringKey)
    }

    private func showOrHideResultLabels(hide: Bool) {
        resultLabels.forEach { $0?.isHidden = hide }
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        currentlyEditing = textField
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
