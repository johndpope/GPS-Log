//
//  LegalProtocol.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/9/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

protocol LegalProtocol: class
{
    func GetDisplayText() -> String
    func GetDisplayHeader() -> String
}
