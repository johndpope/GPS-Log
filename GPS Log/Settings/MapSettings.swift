//
//  MapSettings.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/8/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class MapSettings: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        MapTypeSelector.layer.borderColor = UIColor.black.cgColor
        ShowCurrentLocationSwitch.isOn = UserDefaults.standard.bool(forKey: "ShowCurrentLocation")
        ShowCompassSwitch.isOn = UserDefaults.standard.bool(forKey: "ShowCompass")
        ShowBuildingsSwitch.isOn = UserDefaults.standard.bool(forKey: "ShowBuildings")
        ShowTrafficSwitch.isOn = UserDefaults.standard.bool(forKey: "ShowTraffic")
        ShowScaleSwitch.isOn = UserDefaults.standard.bool(forKey: "ShowScale")
        for SomeType in MapTypes.allCases
        {
            MapSelectorList.append(SomeType.rawValue)
        }
        MapTypeSelector.reloadAllComponents()
        var MapType: MapTypes = .Standard
        if let TheMapType = UserDefaults.standard.string(forKey: "MapType")
        {
            MapType = MapTypes(rawValue: TheMapType)!
        }
        else
        {
            UserDefaults.standard.set("Standard", forKey: "MapType")
            MapType = .Standard
        }
        var Index = 0
        for (TheType, _) in MapTypeMap
        {
            if MapTypes(rawValue: TheType)! == MapType
            {
                MapTypeSelector.selectRow(Index, inComponent: 0, animated: true)
                break
            }
            Index = Index + 1
        }
    }
    
    var MapSelectorList = [String]()
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return MapSelectorList.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        let RawPicked = MapTypeMap[row].0
        let Picked = MapTypes(rawValue: RawPicked)!
        UserDefaults.standard.set(Picked.rawValue, forKey: "MapType")
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return MapSelectorList[row]
    }
    
    let MapTypeMap =
        [
            (MapTypes.Standard.rawValue, MKMapType.standard),
            (MapTypes.MutedStandard.rawValue, MKMapType.mutedStandard),
            (MapTypes.Satellite.rawValue, MKMapType.satellite),
            (MapTypes.Hybrid.rawValue, MKMapType.hybrid),
            (MapTypes.SatelliteFlyover.rawValue, MKMapType.satelliteFlyover),
            (MapTypes.HybridFlyover.rawValue, MKMapType.hybridFlyover)
    ]
    
    @IBAction func HandleShowCurrentLocationChanged(_ sender: Any)
    {
        if let Switch = sender as? UISwitch
        {
            UserDefaults.standard.set(Switch.isOn, forKey: "ShowCurrentLocation")
        }
    }
    
    @IBAction func HandleShowCompassChanged(_ sender: Any)
    {
        if let Switch = sender as? UISwitch
        {
            UserDefaults.standard.set(Switch.isOn, forKey: "ShowCompass")
        }
    }
    
    @IBAction func HandleShowBuildingsChanged(_ sender: Any)
    {
        if let Switch = sender as? UISwitch
        {
            UserDefaults.standard.set(Switch.isOn, forKey: "ShowBuildings")
        }
    }
    
    @IBAction func HandleShowTrafficChanged(_ sender: Any)
    {
        if let Switch = sender as? UISwitch
        {
            UserDefaults.standard.set(Switch.isOn, forKey: "ShowTraffic")
        }
    }
    
    @IBAction func HandleShowScaleChanged(_ sender: Any)
    {
        if let Switch = sender as? UISwitch
        {
            UserDefaults.standard.set(Switch.isOn, forKey: "ShowScale")
        }
    }
    
    @IBOutlet weak var ShowScaleSwitch: UISwitch!
    @IBOutlet weak var ShowTrafficSwitch: UISwitch!
    @IBOutlet weak var ShowBuildingsSwitch: UISwitch!
    @IBOutlet weak var ShowCompassSwitch: UISwitch!
    @IBOutlet weak var ShowCurrentLocationSwitch: UISwitch!
    @IBOutlet weak var MapTypeSelector: UIPickerView!
}

enum MapTypes: String, CaseIterable
{
    case Standard = "Standard"
    case MutedStandard = "Muted Standard"
    case Satellite = "Satellite"
    case Hybrid = "Hybrid"
    case SatelliteFlyover = "Satellite Flyover"
    case HybridFlyover = "Hybrid Flyover"
}
