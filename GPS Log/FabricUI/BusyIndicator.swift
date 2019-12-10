//
//  BusyIndicator.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/9/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import OfficeUIFabric

extension ViewController
{
    /// Initialize the busy indicator.
    func InitializeBusyIndicator()
    {
        BusyIndicatorView.backgroundColor = UIColor.clear
        BusyIndicator = MSActivityIndicatorView(sideSize: BusyIndicatorView.frame.width, strokeThickness: 10.0)
        BusyIndicator.color = UIColor.white
        BusyIndicator.hidesWhenStopped = true
        BusyIndicator.stopAnimating()
        BusyIndicatorView.addSubview(BusyIndicator)
        FetchingText.alpha = 0.0
        BusyIndicatorView.bringSubviewToFront(FetchingText)
        let Tapped = UITapGestureRecognizer(target: self, action: #selector(HandleIndicatorTap))
        Tapped.numberOfTapsRequired = 1
        BusyIndicatorView.addGestureRecognizer(Tapped)
    }
    
    /// Handle taps in the indicator view. When the user taps the view, the busy indicator is hidden (but may be redisplayed
    /// if `ShowBusyIndicator` is called again.
    /// - Parameter Recognizer: The gesture recognizer.
    @objc func HandleIndicatorTap(_ Recognizer: UIGestureRecognizer)
    {
        if Recognizer.state == .ended
        {
            HideBusyIndicator()
        }
    }
    
    /// Show the busy indicator.
    func ShowBusyIndicator()
    {
        FetchingText.text = "Fetching Map"
        FetchingText.alpha = 1.0
        BusyIndicator.RotationDuration = 0.7
        BusyIndicator.color = UIColor.white
        BusyIndicator.startAnimating()
    }
    
    /// Hide the busy indicator.
    func HideBusyIndicator()
    {
        FetchingText.alpha = 0.0
        BusyIndicator.stopAnimating()
    }
    
    /// Show the busy indicator as an error message.
    func ShowErrorIndicator()
    {
        FetchingText.text = "Map Error"
        FetchingText.alpha = 1.0
        BusyIndicator.RotationDuration = 4.0
        BusyIndicator.color = UIColor.red
        BusyIndicator.startAnimating()
    }
}
