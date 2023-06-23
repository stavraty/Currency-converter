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
    private let baseURL = "https://api.privatbank.ua/p24api/pubinfo?exchange&json&coursid=11"
    weak var delegate: CurrencyAPIDelegate?
    
    func fetchCurrencyRates(completion: @escaping ([Currency]?) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let error = error {
                print("Error fetching currency rates:", error)
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
                let currencies = try JSONDecoder().decode([Currency].self, from: data)
                
                self?.saveCurrenciesToCoreData(currencies) {
                    DispatchQueue.main.async {
                        completion(currencies)
                    }
                }
            } catch {
                print("Error decoding currency rates:", error)
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
                print("Error deleting currency rates from CoreData:", error)
                completion()
                return
            }

            for currency in currencies {
                let currencyRate = CurrencyRate(context: context)
                currencyRate.base_ccy = currency.base_ccy
                currencyRate.ccy = currency.ccy
                currencyRate.buy = currency.buy
                currencyRate.sale = currency.sale
                currencyRate.timestamp = currency.timestamp ?? ""
            }
            
            do {
                try context.save()
                print("Currency rates saved successfully (from API)")
                completion()
            } catch {
                print("Error saving currency rates to CoreData:", error)
                completion()
            }
        }
    }
}
