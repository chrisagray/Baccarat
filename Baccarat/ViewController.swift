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
    @IBOutlet weak var bankrollLabel: UILabel!
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
        do {
            try setVariables()
        } catch {
            return showAlert()
        }
        setUserDefaults()
        spinner.isHidden = false
        spinner.startAnimating()
        simulateButton.isHidden = true

        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global().async {
            self.game.run(group: group)
        }

        group.notify(queue: .main) {
            self.simulateButton.isHidden = false
            self.spinner.stopAnimating()
            self.bankrollLabel.text = "End bankroll: \(self.game.betManager.bankroll)"
        }

    }

    private func setVariables() throws {
        guard let shoes = Int(shoesTextField.text ?? ""),
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
