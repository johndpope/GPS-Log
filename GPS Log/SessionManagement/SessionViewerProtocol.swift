//
//  SessionViewerProtocol.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/7/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

protocol SessionViewerProtocol: class
{
    func GetSessionID() -> UUID
    func GetUseTestData() -> Bool
}
