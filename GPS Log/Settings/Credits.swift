//
//  Credits.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/6/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

class Credits: UITableViewController, LegalProtocol
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    //https://stackoverflow.com/questions/25945324/swift-open-link-in-safari
    @IBAction func ShowIconCredits(_ sender: Any)
    {
        let URLToOpen = URL(string: "http://www.onlinewebfonts.com/icon")
        let SafariView = SFSafariViewController(url: URLToOpen!)
        self.present(SafariView, animated: true, completion: nil)
    }
    
    @IBSegueAction func HandleLegalTextInstantiation(_ coder: NSCoder) -> Legal?
    {
        let LegalDialog = Legal(coder: coder)
        LegalDialog?.Delegate = self
        return LegalDialog
    }
    
    func GetDisplayText() -> String
    {
        return MITLicenseText
    }
    
    func GetDisplayHeader() -> String
    {
        return "Microsoft Office UI Fabric"
    }
    
    let MITLicenseText =
"""
Copyright (c) Microsoft Corporation. All rights reserved.

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ""Software""),
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.
"""
}
