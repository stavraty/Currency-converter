//
//  Currency.swift
//  Currency converter
//
//  Created by AS on 16.05.2023.
//

import Foundation

struct Currency: Codable {
    let ccy: String
    let base_ccy: String
    let buy: String
    let sale: String
    let timestamp: String?
}
