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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundViewSettings()
        bodyViewSettings()
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
