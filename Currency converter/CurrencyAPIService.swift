//
//  CurrencyAPI.swift
//  Currency converter
//
//  Created by AS on 16.05.2023.
//

import UIKit
import Foundation
import CoreData

protocol CurrencyAPIDelegate: AnyObject {
    func didFinishFetchingCurrencyRates(_ currencies: [Currency]?)
}

struct CurrencyAPIService {

    weak var delegate: CurrencyAPIDelegate?
    let currencyRepository: CurrencyRepository
    
    init(currencyRepository: CurrencyRepository) {
        self.currencyRepository = currencyRepository
    }

    func fetchCurrencyRates(currentDate: Date? = nil, completion: @escaping ([Currency]?) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let formattedDate: String

        if let currentDate = currentDate {
            formattedDate = dateFormatter.string(from: currentDate)
        } else {
            formattedDate = dateFormatter.string(from: Date())
        }
        
        let baseURL = "https://api.privatbank.ua/p24api/exchange_rates?json&date=\(formattedDate)"
        guard let url = URL(string: baseURL) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            do {
                let response = try JSONDecoder().decode(BankExchangeRate.self, from: data)
                let currencies = response.exchangeRate.map { Currency(baseCurrency: $0.baseCurrency, currency: $0.currency , saleRateNB: $0.saleRateNB , purchaseRateNB: $0.purchaseRateNB, saleRate: $0.saleRate , purchaseRate: $0.purchaseRate, timestamp: response.date) }
                for currency in currencies {
                    self.currencyRepository.saveCurrencyRate(baseCurrencyCode: currency.baseCurrency, currencyCode: currency.currency, buyRate: currency.purchaseRate, sellRate: currency.saleRate, timestamp: currency.timestamp ?? "")
                }
                DispatchQueue.main.async {
                    completion(currencies)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
}
