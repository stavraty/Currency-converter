//
//  ViewController.swift
//  Currency converter
//
//  Created by AS on 09.05.2023.
//

import UIKit
import CoreData

class CurrencyConverterViewController: UIViewController {
    
    enum Constants {
        static let currencyCellIdentifier = "currencyCell"
        static let defaultCurrencyAmount = "0"
        static let defaultCurrencyTitles = ["UAH", "USD"]
    }
    
    enum AlertMessages {
        static let errorTitle = "Error"
        static let fetchCurrencyRatesFailure = "Failed to fetch currency rates"
        static let fetchAPIFailure = "Failed to fetch currency rates from API."
        static let fetchLocalStorageFailure = "Failed to fetch currency rates from local storage."
        static let fetchCurrencyRatesFromAPIFailure = "Currency API is not available."
    }
    
    @IBOutlet weak var firstBackgroundView: UIView!
    @IBOutlet weak var secondBackgroundView: UIView!
    @IBOutlet weak var thirdBackgroundView: UIView!
    @IBOutlet weak var bodyView: UIView!
    @IBOutlet weak var sellBuySegmentedControl: UISegmentedControl!
    @IBOutlet weak var currencyTableView: UITableView!
    @IBOutlet weak var updateDataLabel: UILabel!
    
    private var selectedCurrency: Currency?
    private var currencyRepository: CurrencyRepository?
    private var currencyAPI: CurrencyAPIService?
    private var currencies: [Currency] = []
    private var selectedCurrencies: [Currency] = []
    private var lastEditedIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupRepositories()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchData()
        handleSelectedCurrency()
    }
    
    func currencyCell(_ cell: CurrencyCell, didChangeText text: String?) {
        guard let text = text, let _ = Double(text) else { return }
        lastEditedIndexPath = currencyTableView.indexPath(for: cell)
        convertCurrencyAndUpdateRows(from: lastEditedIndexPath)
    }
    
    func didFinishFetchingCurrencyRates(_ currencies: [Currency]?) {
        guard let currencies = currencies else {
            self.showAlert(title: AlertMessages.errorTitle, message: AlertMessages.fetchCurrencyRatesFailure)
            return
        }
        
        self.currencies = currencies
        
        for currency in currencies {
            self.currencyRepository?.saveCurrencyRate(baseCurrencyCode: currency.baseCurrency, currencyCode: currency.currency, buyRate: currency.purchaseRate, sellRate: currency.saleRate, timestamp: self.getCurrentTimestamp())
        }
        
        DispatchQueue.main.async {
            let currencyRates = self.currencyRepository?.getCurrencyRates() ?? []
            self.currencies = currencyRates
            self.currencyTableView.reloadData()
        }
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
        let currencyRates = currencyRepository?.getCurrencyRates() ?? []
        currencies = currencyRates
        currencyTableView.reloadData()

        if let timestamp = currencyRates.first?.timestamp {
            updateDataLabel(with: timestamp)
        }
    }
    
    private func fetchCurrencyRatesFromAPI() {
        guard let currencyAPI = self.currencyAPI else {
            self.showAlert(title: AlertMessages.errorTitle, message: AlertMessages.fetchCurrencyRatesFromAPIFailure)
            return
        }
        
        currencyAPI.fetchCurrencyRates { currencies in
            guard let currencies = currencies else {
                self.showAlert(title: AlertMessages.errorTitle, message: AlertMessages.fetchAPIFailure)
                return
            }
            self.currencyRepository?.deleteAllCurrencyRates()

            for currency in currencies {
                self.currencyRepository?.saveCurrencyRate(baseCurrencyCode: currency.baseCurrency, currencyCode: currency.currency, buyRate: currency.purchaseRate, sellRate: currency.saleRate, timestamp: self.getCurrentTimestamp())
            }

            DispatchQueue.main.async {
                guard let currencyRates = self.currencyRepository?.getCurrencyRates(), !currencyRates.isEmpty else {
                    self.showAlert(title: AlertMessages.errorTitle, message: AlertMessages.fetchLocalStorageFailure)
                    return
                }

                self.currencies = currencyRates
                self.currencyTableView.reloadData()

                let currentTimestamp = self.getCurrentTimestamp()
                self.updateDataLabel(with: currentTimestamp)
            }
        }
    }
    
    private func findCurrencyCell(for currency: Currency) -> CurrencyCell? {
        for section in 0..<currencyTableView.numberOfSections {
            for row in 0..<currencyTableView.numberOfRows(inSection: section) {
                let indexPath = IndexPath(row: row, section: section)
                guard let cell = currencyTableView.cellForRow(at: indexPath) as? CurrencyCell, cell.currencyButton.currentTitle == currency.currency else {
                    continue
                }
                return cell
            }
        }
        return nil
    }
    
    private func convertCurrency(_ amount: Double, from sourceCurrency: String, to targetCurrency: String, useBuyRate: Bool) -> Double {
        let sourceCurrencyData = currencies.first(where: { $0.currency == sourceCurrency })
        let targetCurrencyData = currencies.first(where: { $0.currency == targetCurrency })

        let sourceRate = useBuyRate ? sourceCurrencyData?.purchaseRate ?? 1.0 : sourceCurrencyData?.saleRate ?? 1.0
        let targetRate = useBuyRate ? targetCurrencyData?.purchaseRate ?? 1.0 : targetCurrencyData?.saleRate ?? 1.0
        
        let convertedAmount = amount * (1 / targetRate) * sourceRate
        return convertedAmount
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func addCurrencyButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let currencySelectionVC = storyboard.instantiateViewController(withIdentifier: "CurrencyListViewController") as! CurrencyListViewController
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
        convertCurrencyAndUpdateRows(from: lastEditedIndexPath)
    }
}

extension CurrencyConverterViewController {
    func setupUI() {
        setupBackgroundView()
        setupBodyView()
        setupGestures()
        setupTableView()
        setupBackButton()
    }
    
    private func setupBackgroundView() {
        firstBackgroundView.layer.cornerRadius = firstBackgroundView.frame.height / 2
        secondBackgroundView.layer.cornerRadius = secondBackgroundView.frame.height / 2
        thirdBackgroundView.layer.cornerRadius = thirdBackgroundView.frame.height / 2
    }
    
    private func setupBodyView() {
        bodyView.layer.borderWidth = 0.2
        bodyView.layer.borderColor = UIColor.lightGray.cgColor
        bodyView.layer.cornerRadius = 10
        bodyView.layer.masksToBounds = false
        bodyView.layer.shadowColor = UIColor.darkGray.cgColor
        bodyView.layer.shadowOffset = CGSize(width: 0, height: 5)
        bodyView.layer.shadowOpacity = 0.5
        bodyView.layer.shadowRadius = 3
    }
    
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    private func setupTableView() {
        currencyTableView.dataSource = self
        currencyTableView.delegate = self
        currencyTableView.register(UINib(nibName: "CurrencyCell", bundle: nil), forCellReuseIdentifier: "currencyCell")
    }
    
    private func setupBackButton() {
        let backItem = UIBarButtonItem()
        backItem.title = "Converter"
        navigationItem.backBarButtonItem = backItem
    }
}

extension CurrencyConverterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row > 1
    }
}

extension CurrencyConverterViewController: UITableViewDataSource, UITextFieldDelegate, CurrencyCellDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedCurrencies.count + Constants.defaultCurrencyTitles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.currencyCellIdentifier, for: indexPath) as? CurrencyCell else {
            return UITableViewCell()
        }

        switch indexPath.row {
        case 0..<Constants.defaultCurrencyTitles.count:
            cell.currencyButton.setTitle(Constants.defaultCurrencyTitles[indexPath.row], for: .normal)
        default:
            let currency = selectedCurrencies[indexPath.row - Constants.defaultCurrencyTitles.count]
            cell.currencyButton.setTitle(currency.currency, for: .normal)
        }

        cell.setUp(currencyAmountTF: Constants.defaultCurrencyAmount, currencyAmountTFTag: indexPath.row + 100, currencyAmountTFDelegate: self, delegate: self)
        
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && indexPath.row >= Constants.defaultCurrencyTitles.count {
            selectedCurrencies.remove(at: indexPath.row - Constants.defaultCurrencyTitles.count)
            tableView.deleteRows(at: [indexPath], with: .left)
        }
    }
}

extension CurrencyConverterViewController: CurrencyListViewControllerDelegate {
    func currencyListViewController(_ viewController: CurrencyListViewController, didSelectCurrency currency: Currency) {
        if currency.currency == Constants.defaultCurrencyTitles[1] {
            let secondRowIndexPath = IndexPath(row: 1, section: 0)
            if let secondCell = currencyTableView.cellForRow(at: secondRowIndexPath) as? CurrencyCell,
               let currentCurrency = secondCell.currencyButton.currentTitle,
               currentCurrency == Constants.defaultCurrencyTitles[1] {
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
}

extension CurrencyConverterViewController: CurrencyAPIDelegate {
    private func setupRepositories() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        currencyRepository = CurrencyRepository(context: context)
        currencyAPI = CurrencyAPIService(currencyRepository: currencyRepository!)
    }
}
