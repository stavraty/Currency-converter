//
//  Currency_converterTests.swift
//  Currency converterTests
//
//  Created by AS on 09.05.2023.
//

import XCTest
@testable import Currency_converter

class CurrencyRepositoryIntegrationTests: XCTestCase {
    var crt: CurrencyRepository!

    override func setUp() {
        super.setUp()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        crt = CurrencyRepository(context: context)
    }

    override func tearDown() {
        crt = nil
        super.tearDown()
    }

    func testFetchingDataFromServer() {
        crt.deleteAllCurrencyRates()

        let urlString = "https://api.privatbank.ua/p24api/exchange_rates?json&date=03.07.2023"
        guard let url = URL(string: urlString) else {
            XCTFail("Invalid URL.")
            return
        }

        let expectation = XCTestExpectation(description: "Currency rates data fetched.")

        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let error = error {
                XCTFail("DataTask error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                XCTFail("Invalid data.")
                return
            }

            do {
                let responseModel = try JSONDecoder().decode(BankExchangeRate.self, from: data)
                for rate in responseModel.exchangeRate {
                    self?.crt.saveCurrencyRate(baseCurrencyCode: rate.baseCurrency,
                                               currencyCode: rate.currency,
                                               buyRate: rate.purchaseRateNB,
                                               sellRate: rate.saleRate,
                                               timestamp: responseModel.date)
                }
                expectation.fulfill()
            } catch {
                XCTFail("Decoding error: \(error)")
            }

        }.resume()

        wait(for: [expectation], timeout: 20.0)
    }
    
    func testCurrencyRateForUSD() {
        let fetchedCurrencyRates = crt.getCurrencyRates()
        let usdRate = fetchedCurrencyRates.first(where: { $0.currency == "USD" })
        XCTAssertNotNil(usdRate)
        XCTAssertEqual(usdRate?.saleRate, 37.25)
        XCTAssertEqual(usdRate?.purchaseRate, 36.75)
    }
}
