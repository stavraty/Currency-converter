//
//  ViewController.swift
//  Currency converter
//
//  Created by AS on 09.05.2023.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var headerBackgroundView: UIView!
    @IBOutlet weak var firstBackgroundView: UIView!
    @IBOutlet weak var secondBackgroundView: UIView!
    @IBOutlet weak var thirdBackgroundView: UIView!
    @IBOutlet weak var bodyView: UIView!
    @IBOutlet weak var sellBuySegmentedControl: UISegmentedControl!
    @IBOutlet weak var currencyTableView: UITableView!

    
    @IBOutlet weak var addCurrencyButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var updateTextLabel: UILabel!
    @IBOutlet weak var updateDataLabel: UILabel!
    
    let currencyAPI = CurrencyAPI()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundViewSettings()
        bodyViewSettings()
        
        currencyAPI.fetchCurrencyRates { currencies in
            if let currencies = currencies {
                // Отримано курси валют, можна оновити таблицю або виконати необхідні дії
                DispatchQueue.main.async {
                    // Оновити вашу таблицю з валютами (currencyTableView)
                }
            } else {
                // Помилка при отриманні курсів валют, можна виконати необхідні дії
            }
        }
    }
    
    func backgroundViewSettings() {
        firstBackgroundView.layer.cornerRadius = firstBackgroundView.frame.height / 2
        secondBackgroundView.layer.cornerRadius = secondBackgroundView.frame.height / 2
        thirdBackgroundView.layer.cornerRadius = thirdBackgroundView.frame.height / 2
    }
    
    func bodyViewSettings() {
        bodyView.layer.borderWidth = 0.2
        bodyView.layer.borderColor = UIColor.lightGray.cgColor
        
        bodyView.layer.cornerRadius = 10
        bodyView.layer.masksToBounds = false
        
        bodyView.layer.shadowColor = UIColor.darkGray.cgColor
        bodyView.layer.shadowOffset = CGSize(width: 0, height: 5)
        bodyView.layer.shadowOpacity = 0.5
        bodyView.layer.shadowRadius = 3
    }

}
