//
//  MainSettings.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/5/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class MainSettings: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        StayAwakeSwitch.isOn = Settings.GetBoolean(ForKey: .StayAwake)
        if Settings.GetBoolean(ForKey: .DiscardDuplicates)
        {
            DuplicateActionLabel.text = "Discard"
        }
        else
        {
            DuplicateActionLabel.text = "Keep"
        }
        FrequencyPicker.layer.borderColor = UIColor.black.cgColor
        FrequencyPicker.reloadAllComponents()
        let Period = Settings.GetInteger(ForKey: .Period)
        var SelectRow = 7
        for Index in 0 ..< UpdateFrequencies.count
        {
            if Period == UpdateFrequencies[Index]
            {
                SelectRow = Index
                break
            }
        }
        FrequencyPicker.selectRow(SelectRow, inComponent: 0, animated: true)
        NotificationCenter.default.addObserver(self, selector: #selector(HandleDefaultChanges), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    /// Handle asynchronous changes to the user default values.
    /// - Note: See: [How to determine when settings change](https://stackoverflow.com/questions/3927402/how-to-determine-when-settings-change-on-ios/33722059#33722059)
    /// - Parameter notification: The change notification.
    @objc func HandleDefaultChanges(notification: Notification)
    {
        if let _ = notification.object as? UserDefaults
        {
            if Settings.GetBoolean(ForKey: .DiscardDuplicates)
            {
                DuplicateActionLabel.text = "Discard"
            }
            else
            {
                DuplicateActionLabel.text = "Keep"
            }
        }
    }
    
    let UpdateFrequencies = [0, 1, 2, 5, 10, 15, 30, 60, 120, 180, 240, 300, 600, 900, 1200, 1800, 3600, 7200]
    let FrequencyLabels =
    [
        "Always",         //0   = 0
        "1 second",       //1   = 1
        "2 seconds",      //2   = 2
        "5 seconds",      //3   = 5
        "10 seconds",     //4   = 10
        "15 seconds",     //5   = 15
        "30 seconds",     //6   = 30
        "1 minute",       //7   = 60
        "2 minutes",      //8   = 120
        "3 minutes",      //9   = 180
        "4 minutes",      //10  = 240
        "5 minutes",      //11  = 300
        "10 minutes",     //12  = 600
        "15 minutes",     //13  = 900
        "20 minutes",     //14  = 1200
        "30 minutes",     //15  = 1800
        "1 hour",         //16  = 3600
        "2 hours"         //17  = 7200
    ]
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return FrequencyLabels[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        UpdateFrequencies.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        let Period = UpdateFrequencies[row]
        Settings.SetInteger(Period, ForKey: .Period)
    }
    
    @IBAction func HandleGetAddressesChanged(_ sender: Any)
    {
        if let Switch = sender as? UISwitch
        {
            Settings.SetBoolean(Switch.isOn, ForKey: .DecodeAddresses)
        }
    }
    
    @IBAction func HandleDonePressed(_ sender: Any)
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func HandleEnableBackgroundChanged(_ sender: Any)
    {
        if let Switch = sender as? UISwitch
        {
            Settings.SetBoolean(Switch.isHidden, ForKey: .CollectDataInBackground)
        }
    }
    
    @IBAction func HandleStayAwakeChanged(_ sender: Any)
    {
        if let Switch = sender as? UISwitch
        {
            Settings.SetBoolean(Switch.isOn, ForKey: .StayAwake)
        }
    }
    
    @IBOutlet weak var StayAwakeSwitch: UISwitch!
    @IBOutlet weak var DuplicateActionLabel: UILabel!
    @IBOutlet weak var FrequencyPicker: UIPickerView!
    @IBOutlet weak var GetAddressesSwitch: UISwitch!
    @IBOutlet weak var BGCollectionSwitch: UISwitch!
}
