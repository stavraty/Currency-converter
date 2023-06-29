//
//  Currency.swift
//  Currency converter
//
//  Created by AS on 16.05.2023.
//

import Foundation

struct BankExchangeRate: Codable {
    let date: String
    let bank: String
    let baseCurrency: Int
    let baseCurrencyLit: String
    let exchangeRate: [Currency]
}

struct Currency: Codable {
    let baseCurrency: String
    let currency: String
    let saleRateNB: Double
    let purchaseRateNB: Double
    let saleRate: Double?
    let purchaseRate: Double?
    let timestamp: String?
}
