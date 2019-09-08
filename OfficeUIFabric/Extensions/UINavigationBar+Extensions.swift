//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import UIKit

@objc public extension UINavigationBar {
    @objc func hideBottomBorder() {
        shadowImage = UIImage()
    }
}
