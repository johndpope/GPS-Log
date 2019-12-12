//
//  Extensions.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/12/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

extension Double
{
    /// Converts the instance value into a radial value.
    var Radians: Double
    {
        get
        {
            return self * Double.pi / 180.0
        }
    }
}
