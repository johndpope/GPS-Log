//
//  AboutController.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/10/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class AboutController: UITableViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        UpdateLabelSizes()
        VersionLabel.text = Versioning.ApplicationName + ", " + Versioning.MakeVersionString() + " " + Versioning.MakeBuildString()
        AuthorLabel.text = "Authors: " + Versioning.AuthorList()
        CopyrightLabel.text = Versioning.ApplicationName + " " + Versioning.CopyrightText()
    }
    
    func UpdateLabelSizes()
    {
        let BaseWidth = self.view.frame.width
        let FinalWidth = BaseWidth - 40.0
        VersionLabel.frame = CGRect(x: VersionLabel.frame.minX,
                                    y: VersionLabel.frame.minY,
                                    width: FinalWidth,
                                    height: VersionLabel.frame.height)
        AuthorLabel.frame = CGRect(x: AuthorLabel.frame.minX,
                                   y: AuthorLabel.frame.minY,
                                   width: FinalWidth,
                                   height: AuthorLabel.frame.height)
        CopyrightLabel.frame = CGRect(x: CopyrightLabel.frame.minX,
                                      y: CopyrightLabel.frame.minY,
                                      width: FinalWidth,
                                      height: CopyrightLabel.frame.height)
    }
    
    @IBOutlet weak var VersionLabel: UILabel!
    @IBOutlet weak var AuthorLabel: UILabel!
    @IBOutlet weak var CopyrightLabel: UILabel!
}
