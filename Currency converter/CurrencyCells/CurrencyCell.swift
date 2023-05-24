//
//  TableViewCell.swift
//  Currency converter
//
//  Created by AS on 17.05.2023.
//

import UIKit

class CurrencyCell: UITableViewCell {
    
    @IBOutlet weak var currencyButton: UIButton!
    @IBOutlet weak var currencyAmountTextField: UITextField!
    
    weak var delegate: CurrencySelectionDelegate?
    var ccy: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    @IBAction func currencyButtonTapped(_ sender: Any) {
        guard let ccy = ccy else { return }
        delegate?.didSelectCurrency(ccy)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
}
