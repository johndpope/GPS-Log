//
//  Legal.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/9/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class Legal: UIViewController
{
    public weak var Delegate: LegalProtocol? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        LegalTextField.layer.borderColor = UIColor.black.cgColor
        LegalHeaderField.text = Delegate?.GetDisplayHeader()
        LegalTextField.text = Delegate?.GetDisplayText()
    }
    
    @IBOutlet weak var LegalTextField: UITextView!
    @IBOutlet weak var LegalHeaderField: UILabel!
}
