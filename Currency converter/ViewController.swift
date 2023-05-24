//
//  ViewController.swift
//  Currency converter
//
//  Created by AS on 09.05.2023.
//

import UIKit
import CoreData

protocol CurrencySelectionDelegate: AnyObject {
    func didSelectCurrency(_ currencyCode: String)
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CurrencySelectionDelegate, CurrencyAPIDelegate {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundViewSettings()
        bodyViewSettings()

        appDelegate = UIApplication.shared.delegate as? AppDelegate
        currencyRepository = appDelegate?.currencyRepository

        currencyTableView.dataSource = self
        currencyTableView.delegate = self

        currencyAPI.delegate = self
        _ = CurrencyRepository(context: (appDelegate?.persistentContainer.viewContext)!)

        if let currencyRates = currencyRepository?.getCurrencyRates() {
            print("Currency rates in Core Data: \(currencyRates)")
        }

        currencyTableView.reloadData()
        
        if let firstCell = currencyTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? CurrencyCell {
            self.firstCell = firstCell
            firstCell.currencyButton.setTitle("UAH", for: .normal)
            firstCell.currencyAmountTextField.text = "100"
        }
        
        fetchCurrencyRates()
    }
    
    func fetchCurrencyRates() {
        currencyAPI.fetchCurrencyRates { currencies in
            if let currencies = currencies {
                print("Fetched currency rates from API: \(currencies)")
                
                if let savedCurrencyRates = self.currencyRepository?.fetchCurrencyRates() {
                    print("Saved currency rates in Core Data:")
                    for currencyRate in savedCurrencyRates {
                        print("Base Currency code: \(currencyRate.base_ccy ?? "")")
                        print("Currency Code: \(String(describing: currencyRate.ccy))")
                        print("Buy Rate: \(String(describing: currencyRate.buy))")
                        print("Sell Rate: \(String(describing: currencyRate.sale))")
                        print("Timestamp: \(String(describing: currencyRate.timestamp))")
                        print("---")
                    }
                } else {
                    print("Failed to fetch saved currency rates from Core Data")
                }

                DispatchQueue.main.async {
                    self.currencyRepository?.deleteAllCurrencyRates() // Видаляємо всі наявні дані перед збереженням нових
                    for currency in currencies {
                        self.currencyRepository?.saveCurrencyRate(baseCurrencyCode: currency.base_ccy, currencyCode: currency.ccy, buyRate: currency.buy, sellRate: currency.sale, timestamp: self.getCurrentTimestamp())
                        print("Зберегти курси валют у Core Data")
                    }
                    
                    if let currencyRates = self.currencyRepository?.getCurrencyRates() {
                        self.currencies = currencyRates
                        self.currencyTableView.reloadData()
                        self.convertCurrencyAndUpdateSecondRow()
                        print("Currency rates in Core Data: \(currencyRates)")
                        
                        if self.currencies.isEmpty {
                            print("Масив currencies порожній після оновлення")
                        } else {
                            print("Масив currencies містить \(self.currencies.count) елементів після оновлення")
                        }
                    }
                }

            } else {
                print("Failed to fetch currency rates from API")
            }
            
            if let currencyRates = self.currencyRepository?.getCurrencyRates() {
                print("Currency rates in Core Data: \(currencyRates)")
            }
        }
    }
    
    func getCurrentTimestamp() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentTimestamp = dateFormatter.string(from: Date())
        return currentTimestamp
    }

    func didSelectCurrency(_ currencyCode: String) {
        if let selectedIndexPath = currencyTableView.indexPathForSelectedRow {
            if let cell = currencyTableView.cellForRow(at: selectedIndexPath) as? CurrencyCell {
                cell.currencyButton.setTitle(currencyCode, for: .normal)
            }
        }
    }
    
    func showCurrencySelection() {
        let currencySelectionController = UIAlertController(title: "Select Currency", message: nil, preferredStyle: .actionSheet)
        
        for currency in currencies {
            let currencyAction = UIAlertAction(title: currency.ccy, style: .default) { [weak self] _ in
                self?.didSelectCurrency(currency.ccy)
            }
            currencySelectionController.addAction(currencyAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        currencySelectionController.addAction(cancelAction)
        
        present(currencySelectionController, animated: true, completion: nil)
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currencies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CurrencyCell", for: indexPath) as! CurrencyCell
        
        cell.currencyAmountTextField.addTarget(self, action: #selector(currencyAmountChanged(_:)), for: .editingChanged)
        cell.delegate = self
        
        if indexPath.row == 0 {
            cell.currencyButton.setTitle("UAH", for: .normal)
        } else if indexPath.row == 1 {
            cell.currencyButton.setTitle("EUR", for: .normal)
        } else {
            let currency = currencies[indexPath.row - 2]
            cell.currencyButton.setTitle(currency.ccy, for: .normal) // Змінено поле для відображення валюти
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currency = currencies[indexPath.row]
        didSelectCurrency(currency.ccy)
    }
    
    func convertCurrencyAndUpdateSecondRow() {
        let firstRowIndexPath = IndexPath(row: 0, section: 0)
        let secondRowIndexPath = IndexPath(row: 1, section: 0)
        
        guard let firstCell = currencyTableView.cellForRow(at: firstRowIndexPath) as? CurrencyCell,
              let secondCell = currencyTableView.cellForRow(at: secondRowIndexPath) as? CurrencyCell,
              let amountString = firstCell.currencyAmountTextField.text,
              let amount = Double(amountString),
              let sourceCurrency = firstCell.currencyButton.titleLabel?.text else {
            print("Conversion failed")
            return
        }
        
        let currency = currencies[secondRowIndexPath.row]
        let convertedAmount = convertCurrency(amount, from: sourceCurrency, to: currency.ccy)
        let convertedText = String(format: "%.2f", convertedAmount)
        
        secondCell.currencyAmountTextField.text = convertedText
    }

    @objc func currencyAmountChanged(_ textField: UITextField) {
        guard textField.tag == 100, let superview = textField.superview as? UITableViewCell, let indexPath = currencyTableView.indexPath(for: superview) else {
            return
        }
        
        let currency = currencies[indexPath.row]
        
        if let text = textField.text, let amount = Double(text) {
            let convertedAmount = convertCurrency(amount, from: firstCell?.currencyButton.titleLabel?.text ?? "UAH", to: currency.ccy)
            let convertedText = String(format: "%.2f", convertedAmount)
            
            let indexPathForConverted = IndexPath(row: 1, section: 0)
            if let convertedCell = currencyTableView.cellForRow(at: indexPathForConverted) as? CurrencyCell {
                convertedCell.currencyAmountTextField.text = convertedText
            }
            
            convertCurrencyAndUpdateSecondRow()
        }
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
                    
                    self.convertCurrencyAndUpdateSecondRow() // Оновити значення в другому рядку після оновлення таблиці
                }
            }
        }
    }

    func convertCurrency(_ amount: Double, from sourceCurrency: String, to targetCurrency: String) -> Double {
        guard let sourceCurrencyRate = currencies.first(where: { $0.ccy == sourceCurrency }),
              let targetCurrencyRate = currencies.first(where: { $0.ccy == targetCurrency }),
              let sourceBuyRate = Double(sourceCurrencyRate.buy),
              let targetBuyRate = Double(targetCurrencyRate.buy) else {
            return 0.0
        }
        
        let convertedAmount = amount * (targetBuyRate / sourceBuyRate)
        return convertedAmount
    }
}
