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
    var amount: Double = 0.0
    var selectedCurrency: Currency?
    var selectedCurrencies: [Currency] = []
    var lastEditedIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackgroundView()
        setupBodyView()
        setupGestures()
        setupRepositories()
        setupTableView()
        setupBackButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchData()
        handleSelectedCurrency()
    }

    private func fetchData() {
        if currencyRepository?.shouldFetchCurrencyRates() ?? false {
            fetchCurrencyRatesFromAPI()
        } else {
            fetchCurrencyRatesFromCoreData()
        }
    }

    private func handleSelectedCurrency() {
        if let currency = selectedCurrency {
            if !selectedCurrencies.contains(where: { $0.currency == currency.currency }) {
                selectedCurrencies.append(currency)
                selectedCurrency = nil
                DispatchQueue.main.async {
                    self.currencyTableView.reloadData()
                }
            }
        }
    }
    
    func setupBackgroundView() {
        firstBackgroundView.layer.cornerRadius = firstBackgroundView.frame.height / 2
        secondBackgroundView.layer.cornerRadius = secondBackgroundView.frame.height / 2
        thirdBackgroundView.layer.cornerRadius = thirdBackgroundView.frame.height / 2
    }
    
    func setupBodyView() {
        bodyView.layer.borderWidth = 0.2
        bodyView.layer.borderColor = UIColor.lightGray.cgColor
        bodyView.layer.cornerRadius = 10
        bodyView.layer.masksToBounds = false
        bodyView.layer.shadowColor = UIColor.darkGray.cgColor
        bodyView.layer.shadowOffset = CGSize(width: 0, height: 5)
        bodyView.layer.shadowOpacity = 0.5
        bodyView.layer.shadowRadius = 3
    }
    
    func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    func setupRepositories() {
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        currencyRepository = CurrencyRepository(context: (appDelegate?.persistentContainer.viewContext)!)
        currencyRepository = appDelegate?.currencyRepository
        currencyAPI.delegate = self
    }

    func setupTableView() {
        currencyTableView.dataSource = self
        currencyTableView.delegate = self
        currencyTableView.register(UINib(nibName: "CurrencyCell", bundle: nil), forCellReuseIdentifier: "currencyCell")
    }

    func setupBackButton() {
        let backItem = UIBarButtonItem()
        backItem.title = "Converter"
        navigationItem.backBarButtonItem = backItem
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedCurrencies.count + 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "currencyCell", for: indexPath) as! CurrencyCell
        
        if indexPath.row == 0 {
            cell.currencyButton.setTitle("UAH", for: .normal)
        } else if indexPath.row == 1 {
            cell.currencyButton.setTitle("USD", for: .normal)
        } else {
            let currency = selectedCurrencies[indexPath.row - 2]
            cell.currencyButton.setTitle(currency.currency, for: .normal)
        }
        cell.currencyAmountTextField.text = "0"
        cell.currencyAmountTextField.tag = indexPath.row + 100
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
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row > 1
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && indexPath.row > 1 {
            selectedCurrencies.remove(at: indexPath.row - 2)
            tableView.deleteRows(at: [indexPath], with: .left)
        }
    }
    
    func currencyCell(_ cell: CurrencyCell, didChangeText text: String?) {
        guard let text = text, let amount = Double(text) else { return }
        lastEditedIndexPath = currencyTableView.indexPath(for: cell)
        convertCurrencyAndUpdateRows(from: lastEditedIndexPath)
    }

    private func convertCurrencyAndUpdateRows(from sourceIndexPath: IndexPath?) {
        guard let sourceIndexPath = sourceIndexPath,
              let sourceCell = currencyTableView.cellForRow(at: sourceIndexPath) as? CurrencyCell,
              let sourceCurrency = sourceCell.currencyButton.currentTitle,
              let amountString = sourceCell.currencyAmountTextField.text,
              let amount = Double(amountString) else {
            return
        }
        
        let useBuyRate = sellBuySegmentedControl.selectedSegmentIndex == 1

        for indexPath in currencyTableView.indexPathsForVisibleRows ?? [] {
            if indexPath != sourceIndexPath {
                guard let targetCell = currencyTableView.cellForRow(at: indexPath) as? CurrencyCell,
                      let targetCurrency = targetCell.currencyButton.currentTitle else {
                    continue
                }
                
                let convertedAmount = convertCurrency(amount, from: sourceCurrency, to: targetCurrency, useBuyRate: useBuyRate)
                
                DispatchQueue.main.async {
                    targetCell.currencyAmountTextField.text = String(format: "%.2f", convertedAmount)
                }
            }
        }
    }
    
    private func getCurrentTimestamp() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy h:mm a"
        let currentTimestamp = dateFormatter.string(from: Date())
        return currentTimestamp
    }
    
    private func updateDataLabel(with timestamp: String) {
        updateDataLabel.text = timestamp
    }
    
    private func fetchCurrencyRates() {
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
    
    private func fetchCurrencyRatesFromCoreData() {
        if let currencyRates = currencyRepository?.getCurrencyRates() {
            currencies = currencyRates
            currencies = currencyRepository?.getCurrencyRates() ?? []
            currencyTableView.reloadData()
            
            if let timestamp = currencyRates.first?.timestamp {
                updateDataLabel(with: timestamp)
            }
        }
    }
    
    private func fetchCurrencyRatesFromAPI() {
        currencyAPI.fetchCurrencyRates { currencies in
            if let currencies = currencies {
                self.currencyRepository?.deleteAllCurrencyRates()
                
                for currency in currencies {
                    self.currencyRepository?.saveCurrencyRate(baseCurrencyCode: currency.baseCurrency, currencyCode: currency.currency, buyRate: currency.purchaseRate, sellRate: currency.saleRate, timestamp: self.getCurrentTimestamp())
                }
                
                DispatchQueue.main.async {
                    if let currencyRates = self.currencyRepository?.getCurrencyRates() {
                        self.currencies = currencyRates
                        self.currencyTableView.reloadData()
                        
                        let currentTimestamp = self.getCurrentTimestamp()
                        self.updateDataLabel(with: currentTimestamp)
                    }
                }
            }
        }
    }
    
    private func findCurrencyCell(for currency: Currency) -> CurrencyCell? {
        for section in 0..<currencyTableView.numberOfSections {
            for row in 0..<currencyTableView.numberOfRows(inSection: section) {
                if let cell = currencyTableView.cellForRow(at: IndexPath(row: row, section: section)) as? CurrencyCell {
                    
                    if cell.currencyButton.currentTitle == currency.currency {
                        return cell
                    }
                }
            }
        }
        return nil
    }
    
    func didFinishFetchingCurrencyRates(_ currencies: [Currency]?) {
        if let currencies = currencies {
            self.currencies = currencies
            
            for currency in currencies {
                self.currencyRepository?.saveCurrencyRate(baseCurrencyCode: currency.baseCurrency, currencyCode: currency.currency, buyRate: currency.purchaseRate, sellRate: currency.saleRate, timestamp: self.getCurrentTimestamp())
            }
            
            DispatchQueue.main.async {
                if let currencyRates = self.currencyRepository?.getCurrencyRates() {
                    self.currencies = currencyRates
                    self.currencyTableView.reloadData()
                }
            }
        }
    }
    
    private func convertCurrency(_ amount: Double, from sourceCurrency: String, to targetCurrency: String, useBuyRate: Bool) -> Double {
        var sourceRate: Double = 1.0
        var targetRate: Double = 1.0
        
        for currency in currencies {
            if currency.currency == sourceCurrency {
                if useBuyRate {
                    if let purchaseRate = currency.purchaseRate {
                        sourceRate = purchaseRate
                    }
                } else {
                    if let saleRate = currency.saleRate {
                        sourceRate = saleRate
                    }
                }
            }
            
            if currency.currency == targetCurrency {
                if useBuyRate {
                    if let purchaseRate = currency.purchaseRate {
                        targetRate = purchaseRate
                    }
                } else {
                    if let saleRate = currency.saleRate {
                        targetRate = saleRate
                    }
                }
            }
        }
        
        let convertedAmount = amount * (1 / targetRate) * sourceRate
        return convertedAmount
    }

    func currencySelectionViewController(_ viewController: CurrencySelectionViewController, didSelectCurrency currency: Currency) {
        if currency.currency == "USD" {
            let secondRowIndexPath = IndexPath(row: 1, section: 0)
            if let secondCell = currencyTableView.cellForRow(at: secondRowIndexPath) as? CurrencyCell,
               let currentCurrency = secondCell.currencyButton.currentTitle,
               currentCurrency == "USD" {
                return
            }
        }
        
        if selectedCurrencies.contains(where: { $0.currency == currency.currency }) {
            return
        }
        self.selectedCurrencies.append(currency)
        DispatchQueue.main.async {
            self.currencyTableView.reloadData()
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func addCurrencyButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let currencySelectionVC = storyboard.instantiateViewController(withIdentifier: "CurrencySelectionViewController") as! CurrencySelectionViewController
        currencySelectionVC.currencies = self.currencies
        currencySelectionVC.delegate = self
        self.navigationController?.pushViewController(currencySelectionVC, animated: true)
    }
    
    @IBAction func tapToShareButton(_ sender: Any) {
        let useBuyRate = sellBuySegmentedControl.selectedSegmentIndex == 1
        let rateType = useBuyRate ? "Buy" : "Sale"
        
        var shareText = "Currency Rates (\(rateType)):\n\n"
        for indexPath in currencyTableView.indexPathsForVisibleRows ?? [] {
            if let cell = currencyTableView.cellForRow(at: indexPath) as? CurrencyCell {
                let currency = cell.currencyButton.currentTitle ?? ""
                let amount = cell.currencyAmountTextField.text ?? "0"
                shareText += "\(currency): \(amount)\n"
            }
        }
        
        if let lastUpdatedDateString = currencyRepository?.getLastUpdateTimestamp() {
            shareText += "\nLast updated: \(lastUpdatedDateString)"
        }

        let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view
        present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func sellBuySegmentChanged(_ sender: Any) {
        let useBuyRate = (sender as AnyObject).selectedSegmentIndex == 1
        convertCurrencyAndUpdateRows(from: lastEditedIndexPath)
    }
}
