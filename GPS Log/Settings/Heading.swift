//
//  Heading.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/8/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class Heading: UITableViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        SaveHeadings.isOn = Settings.GetBoolean(ForKey: .TrackHeadings)
        var Sens = Settings.GetDouble(ForKey: .HeadingSensitivity)
        if Sens == 0.0
        {
            Sens = 1.0
        }
        let Index = DegreeMap[Sens]!
        HeadingSegment.selectedSegmentIndex = Index
    }
    
    @IBAction func HandleSaveHeadingsChanged(_ sender: Any)
    {
        if let Switch = sender as? UISwitch
        {
            Settings.SetBoolean(Switch.isOn, ForKey: .TrackHeadings)
        }
    }
    
    @IBAction func HandleSensitivityChanged(_ sender: Any)
    {
        if let Segment = sender as? UISegmentedControl
        {
            let Index = Segment.selectedSegmentIndex
            for (Value, SegIndex) in DegreeMap
            {
                if SegIndex == Index
                {
                    Settings.SetDouble(Value, ForKey: .HeadingSensitivity)
                    return
                }
            }
        }
    }
    
    let DegreeMap =
    [
        1.0: 0,
        2.0: 1,
        5.0: 2,
        10.0: 3,
        15.0: 4,
        20.0: 5
    ]
    
    @IBOutlet weak var HeadingSegment: UISegmentedControl!
    @IBOutlet weak var SaveHeadings: UISwitch!
}
