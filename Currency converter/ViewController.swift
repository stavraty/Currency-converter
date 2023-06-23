//
//  ViewController.swift
//  Currency converter
//
//  Created by AS on 09.05.2023.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CurrencyAPIDelegate, UITextFieldDelegate, CurrencySelectionViewControllerDelegate, CurrencyCellDelegate {
    
    @IBOutlet weak var headerBackgroundView: UIView!
    @IBOutlet weak var firstBackgroundView: UIView!
    @IBOutlet weak var secondBackgroundView: UIView!
    @IBOutlet weak var thirdBackgroundView: UIView!
    @IBOutlet weak var bodyView: UIView!
    @IBOutlet weak var sellBuySegmentedControl: UISegmentedControl!
    @IBOutlet weak var currencyTableView: UITableView!
    @IBOutlet weak var addCurrencyButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var updateTextLabel: UILabel!
    @IBOutlet weak var updateDataLabel: UILabel!
    
    var appDelegate: AppDelegate?
    var currencyRepository: CurrencyRepository?
    let currencyAPI = CurrencyAPI()
    var currencies: [Currency] = []
    var firstCell: CurrencyCell?
    var currencyCell = "currencyCell"
    var isUsingBuyRate: Bool = false
    var isEditingFirstTextField = false
    var amount: Double = 0.0
    var selectedCurrency: Currency?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundViewSettings()
        bodyViewSettings()
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        currencyRepository = CurrencyRepository(context: (appDelegate?.persistentContainer.viewContext)!)
        currencyRepository = appDelegate?.currencyRepository
        currencyTableView.dataSource = self
        currencyTableView.delegate = self
        currencyTableView.register(UINib(nibName: "CurrencyCell", bundle: nil), forCellReuseIdentifier: "currencyCell")
        currencyAPI.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if currencyRepository?.shouldFetchCurrencyRates() ?? false {
            fetchCurrencyRatesFromAPI()
        } else {
            fetchCurrencyRatesFromCoreData()
        }
        
        if let currency = selectedCurrency {
            if !currencies.contains(where: { $0.ccy == currency.ccy }) {
                currencies.append(currency)
                selectedCurrency = nil
                currencyTableView.reloadData()
            }
        }
    }
    
    func backgroundViewSettings() {
        firstBackgroundView.layer.cornerRadius = firstBackgroundView.frame.height / 2
        secondBackgroundView.layer.cornerRadius = secondBackgroundView.frame.height / 2
        thirdBackgroundView.layer.cornerRadius = thirdBackgroundView.frame.height / 2
    }
    
    func bodyViewSettings() {
        bodyView.layer.borderWidth = 0.2
        bodyView.layer.borderColor = UIColor.lightGray.cgColor
        bodyView.layer.cornerRadius = 10
        bodyView.layer.masksToBounds = false
        bodyView.layer.shadowColor = UIColor.darkGray.cgColor
        bodyView.layer.shadowOffset = CGSize(width: 0, height: 5)
        bodyView.layer.shadowOpacity = 0.5
        bodyView.layer.shadowRadius = 3
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currencies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("tableView(_:cellForRowAt:) called")
        let cell = tableView.dequeueReusableCell(withIdentifier: "currencyCell", for: indexPath) as! CurrencyCell
        print("CurrencyCell created")
        if indexPath.row == 0 {
            cell.currencyButton.setTitle("UAH", for: .normal)
            cell.currencyAmountTextField.text = "0"
            cell.currencyAmountTextField.tag = 100
            firstCell = cell
        } else if indexPath.row == 1 {
            cell.currencyButton.setTitle("USD", for: .normal)
            cell.currencyAmountTextField.text = "0"
            cell.currencyAmountTextField.tag = 101
        } else {
            let currency = currencies[indexPath.row - 2]
            cell.currencyButton.setTitle(currency.ccy, for: .normal)
            cell.currencyAmountTextField.text = "0"
            cell.currencyAmountTextField.tag = indexPath.row + 100
        }
        print("Setting delegate for cell at row \(indexPath.row)")
        cell.currencyAmountTextField.delegate = self
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let secondRowIndexPath = IndexPath(row: 1, section: 0)
        guard let secondCell = tableView.cellForRow(at: secondRowIndexPath) as? CurrencyCell else {
            return
        }
        let currencyAmountTextField = secondCell.currencyAmountTextField
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("Did begin editing: \(textField)")
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        print("Method called with string: \(string)")

        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        let allowedCharacterSet = CharacterSet(charactersIn: "0123456789\(decimalSeparator)")
        let replacementStringCharacterSet = CharacterSet(charactersIn: string)
        let isNumeric = allowedCharacterSet.isSuperset(of: replacementStringCharacterSet)

        if string == decimalSeparator && textField.text!.contains(decimalSeparator) {
            print("Double decimal separator detected")
            return false
        }

        guard isNumeric else {
            print("Non numeric input detected")
            return false
        }

        guard let superview = textField.superview as? UITableViewCell,
              let indexPath = currencyTableView.indexPath(for: superview),
              let cell = currencyTableView.cellForRow(at: indexPath) as? CurrencyCell else {
            print("Cannot cast to CurrencyCell")
            return true
        }

        let updatedText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        print("Updated text is: \(updatedText)")

        if updatedText.isEmpty {
            print("Updated text is empty")
            textField.text = updatedText
            convertCurrencyAndUpdateSecondRow()
            return false
        } else if updatedText == "0" && string != "." {
            print("Updated text is zero")
            textField.text = string
            convertCurrencyAndUpdateSecondRow()
            return false
        }

        if textField == firstCell?.currencyAmountTextField {
            print("First cell is being edited")
            for indexPath in currencyTableView.indexPathsForVisibleRows ?? [] {
                guard let cell = currencyTableView.cellForRow(at: indexPath) as? CurrencyCell else {
                    print("Cannot cast to CurrencyCell")
                    continue
                }

                let currency = currencies[indexPath.row]
                let useBuyRate = sellBuySegmentedControl.selectedSegmentIndex == 1
                let convertedAmount = convertCurrency(Double(updatedText) ?? 0.0, from: "UAH", to: currency.ccy, useBuyRate: useBuyRate)
                cell.currencyAmountTextField.text = String(format: "%.2f", convertedAmount)
            }
        } else if textField == cell.currencyAmountTextField {
            print("Other cell is being edited")
            let currency = currencies[0]
            let useBuyRate = sellBuySegmentedControl.selectedSegmentIndex == 1
            let convertedAmount = convertCurrency(Double(updatedText) ?? 0.0, from: currency.ccy, to: "UAH", useBuyRate: useBuyRate)
            firstCell?.currencyAmountTextField.text = String(format: "%.2f", convertedAmount)
        }
        print("Current textField text: \(textField.text ?? "nil")")
        return false
    }

    
    func currencyCell(_ cell: CurrencyCell, didChangeText text: String?) {
        guard let text = text, let amount = Double(text) else { return }
        convertCurrencyAndUpdateSecondRow()
    }
    
    func fetchCurrencyRates() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy h:mm a"
        
        if let lastUpdatedDateString = currencyRepository?.getLastUpdateTimestamp(),
           let lastUpdatedDate = dateFormatter.date(from: lastUpdatedDateString),
           let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date()),
           lastUpdatedDate > oneHourAgo {
            fetchCurrencyRatesFromCoreData()
        } else {
            fetchCurrencyRatesFromAPI()
        }
    }
    
    func fetchCurrencyRatesFromCoreData() {
        if let currencyRates = currencyRepository?.getCurrencyRates() {
            currencies = currencyRates
            currencies = currencyRepository?.getCurrencyRates() ?? []
            currencyTableView.reloadData()
            convertCurrencyAndUpdateSecondRow()
            //  print("Currency rates from Core Data: \(currencyRates)")
            
            if let timestamp = currencyRates.first?.timestamp {
                updateDataLabel(with: timestamp)
            }
        } else {
            print("Failed to fetch currency rates from Core Data")
        }
    }
    
    func fetchCurrencyRatesFromAPI() {
        currencyAPI.fetchCurrencyRates { currencies in
            if let currencies = currencies {
                self.currencyRepository?.deleteAllCurrencyRates()
                
                for currency in currencies {
                    self.currencyRepository?.saveCurrencyRate(baseCurrencyCode: currency.base_ccy, currencyCode: currency.ccy, buyRate: currency.buy, sellRate: currency.sale, timestamp: self.getCurrentTimestamp())
                    print("Save currency rates to Core Data (ViewController)")
                }
                
                DispatchQueue.main.async {
                    if let currencyRates = self.currencyRepository?.getCurrencyRates() {
                        self.currencies = currencyRates
                        self.currencyTableView.reloadData()
                        self.convertCurrencyAndUpdateSecondRow()
                        
                        let currentTimestamp = self.getCurrentTimestamp()
                        self.updateDataLabel(with: currentTimestamp)
                        
                        print("Currency rates in Core Data: \(currencyRates)")
                        
                        if self.currencies.isEmpty {
                            print("The currencies array is empty after updating")
                        } else {
                            print("The currencies array contains \(self.currencies.count) elements after updating (ViewController)")
                        }
                    }
                }
            } else {
                print("Failed to fetch currency rates from API")
            }
        }
    }
    
    func getCurrentTimestamp() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy h:mm a"
        let currentTimestamp = dateFormatter.string(from: Date())
        return currentTimestamp
    }
    
    func updateDataLabel(with timestamp: String) {
        updateDataLabel.text = timestamp
    }
    
    func findCurrencyCell(for currency: Currency) -> CurrencyCell? {
        for section in 0..<currencyTableView.numberOfSections {
            for row in 0..<currencyTableView.numberOfRows(inSection: section) {
                if let cell = currencyTableView.cellForRow(at: IndexPath(row: row, section: section)) as? CurrencyCell {
                    
                    if cell.currencyButton.currentTitle == currency.ccy {
                        return cell
                    }
                }
            }
        }
        return nil
    }
    
    func convertCurrencyAndUpdateSecondRow() {
        let firstRowIndexPath = IndexPath(row: 0, section: 0)
        let secondRowIndexPath = IndexPath(row: 1, section: 0)
        
        guard let firstCell = currencyTableView.cellForRow(at: firstRowIndexPath) as? CurrencyCell,
              let secondCell = currencyTableView.cellForRow(at: secondRowIndexPath) as? CurrencyCell,
              let amountString = firstCell.currencyAmountTextField.text,
              let amount = Double(amountString),
              let sourceCurrency = firstCell.currencyButton.currentTitle,
              let targetCurrency = secondCell.currencyButton.currentTitle else {
            print("Conversion failed")
            return
        }

        let useBuyRate = sellBuySegmentedControl.selectedSegmentIndex == 1
        
        for indexPath in currencyTableView.indexPathsForVisibleRows ?? [] {
            if indexPath != firstRowIndexPath && indexPath != secondRowIndexPath {
                guard let cell = currencyTableView.cellForRow(at: indexPath) as? CurrencyCell,
                      let targetAmountString = cell.currencyAmountTextField.text,
                      let targetAmount = Double(targetAmountString) else {
                    print("Conversion failed for cell at indexPath: \(indexPath)")
                    continue
                }
                
                let currency = currencies[indexPath.row]
                let convertedAmount = convertCurrency(targetAmount, from: targetCurrency, to: currency.ccy, useBuyRate: useBuyRate)
                
                DispatchQueue.main.async {
                    cell.currencyAmountTextField.text = String(format: "%.2f", convertedAmount)
                }
            }
        }
        
        let convertedAmount = convertCurrency(amount, from: sourceCurrency, to: targetCurrency, useBuyRate: useBuyRate)
        
        DispatchQueue.main.async {
            secondCell.currencyAmountTextField.text = String(format: "%.2f", convertedAmount)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        convertCurrencyAndUpdateSecondRow()
        
        guard let superview = textField.superview as? UITableViewCell, let indexPath = currencyTableView.indexPath(for: superview), let cell = currencyTableView.cellForRow(at: indexPath) as? CurrencyCell else {
            return
        }
        cell.currencyAmountTextField.text = textField.text
    }
    
    func didFinishFetchingCurrencyRates(_ currencies: [Currency]?) {
        if let currencies = currencies {
            self.currencies = currencies
            
            for currency in currencies {
                self.currencyRepository?.saveCurrencyRate(baseCurrencyCode: currency.base_ccy, currencyCode: currency.ccy, buyRate: currency.buy, sellRate: currency.sale, timestamp: self.getCurrentTimestamp())
            }
            
            DispatchQueue.main.async {
                if let currencyRates = self.currencyRepository?.getCurrencyRates() {
                    self.currencies = currencyRates
                    self.currencyTableView.reloadData()
                    
                    print("Updated currency rates: \(self.currencies)")
                    
                    if self.currencies.isEmpty {
                        print("Масив currencies порожній після оновлення")
                    } else {
                        print("Масив currencies містить \(self.currencies.count) елементів після оновлення")
                    }
                    
                    self.convertCurrencyAndUpdateSecondRow()
                    print(self.currencies)
                }
            }
        }
    }
    
    func convertCurrency(_ amount: Double, from sourceCurrency: String, to targetCurrency: String, useBuyRate: Bool) -> Double {
        var sourceRate: Double = 1.0
        var targetRate: Double = 1.0
        
        for currency in currencies {
            if currency.ccy == sourceCurrency {
                if useBuyRate {
                    if let buyRate = Double(currency.buy) {
                        sourceRate = buyRate
                    } else {
                        return 0.0
                    }
                } else {
                    if let saleRate = Double(currency.sale) {
                        sourceRate = saleRate
                    } else {
                        return 0.0
                    }
                }
            }
            
            if currency.ccy == targetCurrency {
                if useBuyRate {
                    if let buyRate = Double(currency.buy) {
                        targetRate = buyRate
                    } else {
                        return 0.0
                    }
                } else {
                    if let saleRate = Double(currency.sale) {
                        targetRate = saleRate
                    } else {
                        return 0.0
                    }
                }
            }
        }
        
        let convertedAmount = amount * (1 / targetRate) * sourceRate
        print(convertedAmount)
        return convertedAmount
    }

    
    @IBAction func addCurrencyButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let currencySelectionVC = storyboard.instantiateViewController(withIdentifier: "CurrencySelectionViewController") as! CurrencySelectionViewController
        currencySelectionVC.currencies = self.currencies
        currencySelectionVC.delegate = self
        self.navigationController?.pushViewController(currencySelectionVC, animated: true)
    }
    
    func currencySelectionViewController(_ viewController: CurrencySelectionViewController, didSelectCurrency currency: Currency) {
        selectedCurrency = currency
        navigationController?.popViewController(animated: true)
        currencyTableView.reloadData()
    }
    
    @IBAction func tapToShareButton(_ sender: Any) {
        self.convertCurrencyAndUpdateSecondRow()
    }
    
    @IBAction func sellBuySegmentChanged(_ sender: Any) {
        let useBuyRate = (sender as AnyObject).selectedSegmentIndex == 1
        convertCurrencyAndUpdateSecondRow()
    }
}
