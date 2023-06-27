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

class CurrencyAPI {

    weak var delegate: CurrencyAPIDelegate?
    
    func fetchCurrencyRates(completion: @escaping ([Currency]?) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let currentDate = dateFormatter.string(from: Date())
        let baseURL = "https://api.privatbank.ua/p24api/exchange_rates?json&date=\(currentDate)"
        guard let url = URL(string: baseURL) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
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
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                let currencies = response.exchangeRate.map { Currency(baseCurrency: $0.baseCurrency, currency: $0.currency , saleRateNB: $0.saleRateNB , purchaseRateNB: $0.purchaseRateNB, saleRate: $0.saleRate , purchaseRate: $0.purchaseRate, timestamp: response.date) }
                self?.saveCurrenciesToCoreData(currencies) {
                    DispatchQueue.main.async {
                        completion(currencies)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }

    private func saveCurrenciesToCoreData(_ currencies: [Currency], completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                completion()
                return
            }
            
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CurrencyRate")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
            } catch {
                completion()
                return
            }

            for currency in currencies {
                guard let purchaseRate = currency.purchaseRate, let saleRate = currency.saleRate else {
                    continue
                }
                
                let currencyRate = CurrencyRate(context: context)
                currencyRate.baseCurrency = currency.baseCurrency
                currencyRate.currency = currency.currency
                currencyRate.purchaseRate = purchaseRate
                currencyRate.saleRate = saleRate
                currencyRate.timestamp = currency.timestamp ?? ""
            }
            
            do {
                try context.save()
                completion()
            } catch {
                completion()
            }
        }
    }
}

