//
//  Currency_converterTests.swift
//  Currency converterTests
//
//  Created by AS on 09.05.2023.
//

import XCTest
@testable import Currency_converter

class CurrencyRepositoryIntegrationTests: XCTestCase {
    var sut: CurrencyAPIService!
    
    override func setUp() {
        super.setUp()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let currencyRepository = CurrencyRepository(context: context)
        sut = CurrencyAPIService(currencyRepository: currencyRepository)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testFetchingDataFromServer() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        guard let specificDate = dateFormatter.date(from: "03.07.2023") else {
            XCTFail("Invalid Date.")
            return
        }

        let expectation = XCTestExpectation(description: "Currency rates data fetched.")

        sut.fetchCurrencyRates(currentDate: specificDate) { (currencies) in
            guard let currencies = currencies else {
                XCTFail("Currency fetch failed")
                return
            }

            let usdRate = currencies.first(where: { $0.currency == "USD" })

            XCTAssertEqual(usdRate?.saleRate, 37.25)
            XCTAssertEqual(usdRate?.purchaseRate, 36.75)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 60.0)
    }
}
