//
//  SessionsNavigator.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/9/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class SessionsNavigator: UINavigationController
{
        public weak var Main: MainProtocol? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    @IBSegueAction func HandleSessionsListInstantiated(_ coder: NSCoder) -> SessionList?
    {
        let SList = SessionList(coder: coder)
        SList?.Main = Main
        return SList
    }
}
