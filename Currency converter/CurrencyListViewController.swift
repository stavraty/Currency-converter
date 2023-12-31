//
//  CurrencySelectionViewController.swift
//  Currency converter
//
//  Created by AS on 20.06.2023.
//

import UIKit

protocol CurrencyListViewControllerDelegate: AnyObject {
    func currencyListViewController(_ viewController: CurrencyListViewController, didSelectCurrency currency: Currency)
}

class CurrencyListViewController: UIViewController {
    
    @IBOutlet weak var currencyTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    weak var delegate: CurrencyListViewControllerDelegate?
    var currencies: [Currency] = []
    private var sortedCurrencies = [[Currency]]()
    private var sectionTitles = [String]()
    private let currencyFullNameMap: [String: String] = [
        "AUD": "Australian Dollar",
        "AZN": "Azerbaijanian Manat",
        "BYN": "Belarussian Ruble",
        "CAD": "Canadian Dollar",
        "CHF": "Swiss Franc",
        "CNY": "Yuan Renminbi",
        "CZK": "Czech Koruna",
        "DKK": "Danish Krone",
        "EUR": "EURO",
        "GBP": "Pound Sterling",
        "GEL": "Lari",
        "ILS": "New Israeli Sheqel",
        "KZT": "Tenge",
        "NOK": "Norwegian Krone",
        "PLN": "Zloty",
        "SEK": "Swedish Krona",
        "TMT": "Turkmenistan New Manat",
        "UAH": "Hryvnia",
        "USD": "US Dollar",
        "UZS": "Uzbekistan Sum",
        "XAU": "Gold"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSearchBar()
        sortCurrencies()
        setupTableView()
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
    }
    
    private func sortCurrencies() {
        currencies.sort { $0.currency < $1.currency }
        
        let groupedCurrencies = Dictionary(grouping: currencies, by: { String($0.currency.prefix(1)) })
        sectionTitles = [String](groupedCurrencies.keys).sorted()
        sortedCurrencies = sectionTitles.map { groupedCurrencies[$0] ?? [] }
    }
    
    private func setupTableView() {
        currencyTableView.delegate = self
        currencyTableView.dataSource = self
    }
}

extension CurrencyListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCurrency = sortedCurrencies[indexPath.section][indexPath.row]
        delegate?.currencyListViewController(self, didSelectCurrency: selectedCurrency)
        self.navigationController?.popViewController(animated: true)
    }
}

extension CurrencyListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedCurrencies[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CurrencySelection", for: indexPath)
        let currency = sortedCurrencies[indexPath.section][indexPath.row]
        if let fullName = currencyFullNameMap[currency.currency] {
            cell.textLabel?.text = "\(currency.currency) - \(fullName)"
        } else {
            cell.textLabel?.text = currency.currency
        }
        return cell
    }
}

extension CurrencyListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            let groupedCurrencies = Dictionary(grouping: currencies, by: { String($0.currency.prefix(1)) })
            sectionTitles = [String](groupedCurrencies.keys).sorted()
            sortedCurrencies = sectionTitles.map { groupedCurrencies[$0] ?? [] }
        } else {
            let filteredCurrencies = currencies.filter { $0.currency.contains(searchText) }
            let groupedCurrencies = Dictionary(grouping: filteredCurrencies, by: { String($0.currency.prefix(1)) })
            sectionTitles = [String](groupedCurrencies.keys).sorted()
            sortedCurrencies = sectionTitles.map { groupedCurrencies[$0] ?? [] }
        }
        currencyTableView.reloadData()
    }
}
