//
//  CurrencySelectionViewController.swift
//  Currency converter
//
//  Created by AS on 20.06.2023.
//

import UIKit

protocol CurrencySelectionViewControllerDelegate: AnyObject {
    func currencySelectionViewController(_ viewController: CurrencySelectionViewController, didSelectCurrency currency: Currency)
}

class CurrencySelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var currencyTableView: UITableView!
    
    weak var delegate: CurrencySelectionViewControllerDelegate?
    var currencies: [Currency] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currencyTableView.delegate = self
        currencyTableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currencies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CurrencySelection", for: indexPath)
        let currency = currencies[indexPath.row]
        cell.textLabel?.text = currency.ccy
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCurrency = currencies[indexPath.row]
        print("Выбранная валюта: \(selectedCurrency.ccy)")
        delegate?.currencySelectionViewController(self, didSelectCurrency: selectedCurrency)
        self.navigationController?.popViewController(animated: true)
    }
}
