//
//  DuplicateLocationView.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/8/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class DuplicateLocationView: UITableViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        DiscardDuplicatesSwitch.isOn = UserDefaults.standard.bool(forKey: "DiscardDuplicates")
        let HSeg = SegmentForRadial(UserDefaults.standard.double(forKey: "HorizontalCloseness"))
        HorizontalDuplicateRadius.selectedSegmentIndex = HSeg
        let VSeg = SegmentForRadial(UserDefaults.standard.double(forKey: "VerticalCloseness"))
        VerticalDuplicateRadius.selectedSegmentIndex = VSeg
    }
    
    @IBAction func HandleDiscardDuplicatesChanged(_ sender: Any)
    {
        if let Switch = sender as? UISwitch
        {
            UserDefaults.standard.set(Switch.isOn, forKey: "DiscardDuplicates")
        }
    }
    
    @IBAction func HandleHorizontalRadiusChanged(_ sender: Any)
    {
        if let Radius = RadialMap[HorizontalDuplicateRadius.selectedSegmentIndex]
        {
            UserDefaults.standard.set(Radius, forKey: "HorizontalCloseness")
        }
        else
        {
            fatalError("Invalid segment (\(HorizontalDuplicateRadius.selectedSegmentIndex)) encountered.")
        }
    }
    
    @IBAction func HandleVerticalRadiusChanged(_ sender: Any)
    {
        if let Radius = RadialMap[VerticalDuplicateRadius.selectedSegmentIndex]
        {
            UserDefaults.standard.set(Radius, forKey: "VerticalCloseness")
        }
        else
        {
            fatalError("Invalid segment (\(VerticalDuplicateRadius.selectedSegmentIndex)) encountered.")
        }
    }
    
    let RadialMap =
        [
            0: 5.0,
            1: 10.0,
            2: 20.0,
            3: 50.0,
            4: 100.0
    ]
    
    func SegmentForRadial(_ Radial: Double) -> Int
    {
        for (Index, Radius) in RadialMap
        {
            if Radius == Radial
            {
                return Index
            }
        }
        fatalError("Invalid Radial value: \(Radial)")
    }
    
    @IBOutlet weak var VerticalDuplicateRadius: UISegmentedControl!
    @IBOutlet weak var HorizontalDuplicateRadius: UISegmentedControl!
    @IBOutlet weak var DiscardDuplicatesSwitch: UISwitch!
}
