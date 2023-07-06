//
//  Currency_converterUITests.swift
//  Currency converterUITests
//
//  Created by AS on 09.05.2023.
//

import UIKit
import XCTest
@testable import Currency_converter

class CurrencyConverterVC_UITests: XCTestCase {

    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        continueAfterFailure = false
        app.launch()
    }

    func testTapToAddCurrencyButton() {
        app.buttons["AddCurrencyButton"].tap()
        app.tables.staticTexts["EUR - EURO"].tap()

        let tableCells = app.tables.cells.allElementsBoundByIndex

        for cell in tableCells {
            let currencyButton = cell.buttons.matching(identifier: "currencyButton")
            let predicate = NSPredicate(format: "label == %@", "EUR")
            let eurButton = currencyButton.element(matching: predicate)
            
            if eurButton.exists {
                XCTAssertTrue(eurButton.exists)
                break
            }
        }
    }
    
    func testAddingExistingCurrency() {
        app.buttons["AddCurrencyButton"].tap()
        app.tables.staticTexts["USD - US Dollar"].tap()

        let tableCells = app.tables.cells.allElementsBoundByIndex
        var testButtonCount = 0

        for cell in tableCells {
            let currencyButton = cell.buttons.matching(identifier: "currencyButton")
            let predicate = NSPredicate(format: "label == %@", "USD")
            let testButton = currencyButton.element(matching: predicate)
            
            if testButton.exists {
                testButtonCount += 1
            }
        }
        XCTAssertEqual(testButtonCount, 1, "There should only be one USD button")
    }

    func testConvertingCurrency() {
        let tableCells = app.tables.cells.allElementsBoundByIndex
        
        var uahTextField: XCUIElement?
        var usdTextField: XCUIElement?

        for cell in tableCells {
            let currencyButton = cell.buttons.matching(identifier: "currencyButton")
            let uahPredicate = NSPredicate(format: "label == %@", "UAH")
            let usdPredicate = NSPredicate(format: "label == %@", "USD")

            if currencyButton.element(matching: uahPredicate).exists {
                uahTextField = cell.textFields["currencyTF"]
            }

            if currencyButton.element(matching: usdPredicate).exists {
                usdTextField = cell.textFields["currencyTF"]
            }
        }
        
        guard let uahTF = uahTextField, let usdTF = usdTextField else {
            XCTFail("Required text fields are missing.")
            return
        }

        uahTF.tap()
        uahTF.typeText("1000")
        XCTAssertEqual(usdTF.value as? String, "26.85")
    }
    
    func testCurrencyTextFieldRestrictsNonNumericInput() {
        let tableCells = app.tables.cells.allElementsBoundByIndex
        var uahTextField: XCUIElement?

        for cell in tableCells {
            let currencyButton = cell.buttons.matching(identifier: "currencyButton")
            let uahPredicate = NSPredicate(format: "label == %@", "UAH")

            if currencyButton.element(matching: uahPredicate).exists {
                uahTextField = cell.textFields["currencyTF"]
            }
        }

        guard let uahTF = uahTextField else {
            XCTFail("Required text field is missing.")
            return
        }

        uahTF.tap()
        uahTF.typeText("Qwerty")
        XCTAssertEqual(uahTF.value as? String, "")

        uahTF.tap()
        uahTF.typeText("12qwert34")
        XCTAssertEqual(uahTF.value as? String, "1234")
    }

}
