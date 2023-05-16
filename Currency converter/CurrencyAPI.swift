//
//  CurrencyAPI.swift
//  Currency converter
//
//  Created by AS on 16.05.2023.
//

import Foundation

class CurrencyAPI {
    private let baseURL = "https://api.privatbank.ua/p24api/pubinfo"
    private let exchangePath = "exchange"
    private let jsonFormat = "json"
    private let courseIdParam = "coursid"
    
    // Метод для отримання курсу валют з API
    func fetchCurrencyRates(completion: @escaping ([Currency]?) -> Void) {
        let urlString = "\(baseURL)?\(exchangePath)&\(jsonFormat)&\(courseIdParam)=5"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error fetching currency rates:", error)
                completion(nil)
                return
            }
            
            guard let data = data else {
                completion(nil)
                return
            }
            
            do {
                let currencies = try JSONDecoder().decode([Currency].self, from: data)
                completion(currencies)
            } catch {
                print("Error decoding currency rates:", error)
                completion(nil)
            }
        }.resume()
    }
}
