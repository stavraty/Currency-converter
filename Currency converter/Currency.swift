//
//  Currency.swift
//  Currency converter
//
//  Created by AS on 16.05.2023.
//

import Foundation

struct Currency: Codable {
    let currencyCode: String
    let baseCurrencyCode: String
    let buy: Double
    let sale: Double
}
