//
//  MainDelegate.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/7/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import SQLite3

protocol MainProtocol: class
{
    func Handle() -> OpaquePointer?
}
