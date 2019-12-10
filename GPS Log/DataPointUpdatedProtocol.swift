//
//  DataPointUpdatedProtocol.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/5/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation

protocol DataPointUpdatedProtocol: class
{
    func HaveAddress(ThePoint: DataPoint, TheAddress: String)
}
