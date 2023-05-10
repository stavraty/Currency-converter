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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundViewSettings()
    }
    func backgroundViewSettings() {
        firstBackgroundView.layer.cornerRadius = firstBackgroundView.frame.height / 2
        secondBackgroundView.layer.cornerRadius = secondBackgroundView.frame.height / 2
        thirdBackgroundView.layer.cornerRadius = thirdBackgroundView.frame.height / 2
    }

}
