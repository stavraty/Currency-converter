//
//  TableViewCell.swift
//  Currency converter
//
//  Created by AS on 17.05.2023.
//

import UIKit

protocol CurrencyCellDelegate: AnyObject {
    func currencyCell(_ cell: CurrencyCell, didChangeText text: String?)
}

class CurrencyCell: UITableViewCell {
    
    @IBOutlet weak var currencyButton: UIButton!
    @IBOutlet weak var currencyAmountTextField: UITextField!

    var ccy: String?
    weak var delegate: CurrencyCellDelegate?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        currencyAmountTextField.delegate = self
        currencyAmountTextField.addTarget(self, action: #selector(currencyAmountTextFieldDidChange(_:)), for: .editingChanged)
    }
    
    @IBAction func currencyButtonTapped(_ sender: Any) {
        // delegate?.didTapCurrencyButton(cell: self)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    @objc func currencyAmountTextFieldDidChange(_ textField: UITextField) {
        delegate?.currencyCell(self, didChangeText: textField.text)
    }
}

extension CurrencyCell: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        return allowedCharacters.isSuperset(of: characterSet)
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
}
