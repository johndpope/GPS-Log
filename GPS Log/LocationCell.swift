//
//  LocationCell.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation

class LocationCell: UITableViewCell
{
    public static let CellHeight: CGFloat = 60.0
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        CreateUI()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        CreateUI()
    }
    
    func CreateUI()
    {
        CoordinatesLabel = UILabel(frame: CGRect(x: 5, y: 5, width: 100, height: 20))
        contentView.addSubview(CoordinatesLabel)
        TimeLabel = UILabel(frame: CGRect(x: 5, y: 35, width: 100, height: 20))
        contentView.addSubview(TimeLabel)
        AddressLabel = UILabel(frame: CGRect(x: 101, y: 1, width: 100, height: LocationCell.CellHeight - 2.0))
        AddressLabel.numberOfLines = 4
        AddressLabel.font = UIFont.systemFont(ofSize: 10.0)
        contentView.addSubview(AddressLabel)
    }
    
    var CoordinatesLabel: UILabel!
    var TimeLabel: UILabel!
    var AddressLabel: UILabel!
    
    /// Load data to display in the cell.
    /// - Note: Assumes `CreateUI` has already been called. If not, runtime errors will occur.
    /// - Parameter LocationData: The location data whose coordinates will be displayed.
    /// - Parameter TableWidth: The width of the hosting table. Used to properly calculate the
    ///                         widths and horizontal locations of the various controls.
    /// - Parameter MainFontSize: If present, the font size to use with the coordinates and date. If
    ///                           nil, default sizes will be used.
    /// - Parameter SubFontSize: If present, the font size to use with the address. If nil, default
    ///                          sizes will be used.
    public func LoadData(LocationData: DataPoint, TableWidth: CGFloat, MainFontSize: CGFloat? = nil,
                         SubFontSize: CGFloat? = nil)
    {
        if LocationData.IsMarked
        {
            self.backgroundColor = UIColor.yellow
        }
        else
        {
            self.backgroundColor = UIColor.white
        }
        CoordinatesLabel.frame = CGRect(x: CoordinatesLabel.frame.minX,
                                        y: CoordinatesLabel.frame.minY,
                                        width: TableWidth / 2.0,
                                        height: CoordinatesLabel.frame.height)
        TimeLabel.frame = CGRect(x: TimeLabel.frame.minX,
                                 y: TimeLabel.frame.minY,
                                 width: TableWidth / 2.0,
                                 height: TimeLabel.frame.height)
        AddressLabel.frame = CGRect(x: TableWidth / 2.0,
                                    y: AddressLabel.frame.minY,
                                    width: TableWidth / 2.0,
                                    height: AddressLabel.frame.height)
        
        if let BigFontSize = MainFontSize
        {
            CoordinatesLabel.font = UIFont.systemFont(ofSize: BigFontSize)
            TimeLabel.font = UIFont.systemFont(ofSize: BigFontSize)
        }
        if let SmallFontSize = SubFontSize
        {
            AddressLabel.font = UIFont.systemFont(ofSize: SmallFontSize)
        }
        
        if LocationData.IsHeadingChange
        {
            self.backgroundColor = UIColor(red: 175.0 / 255.0, green: 216.0 / 255.0, blue: 245.0 / 255.0, alpha: 1.0)  //"Uranian Blue"
            let HeadingValue = LocationData.Heading?.trueHeading ?? LocationData.HeadingValue
            let HeadingString = Utilities.RoundedString(Value: HeadingValue, Precision: 3) + "°"
            if LocationData.Heading == nil
            {
                TimeLabel.text = Utilities.DateToString(LocationData.HeadingTimeStamp!)
                AddressLabel.text = ""
                CoordinatesLabel.text = "Heading to \(HeadingString)"
            }
            else
            {
                TimeLabel.text = Utilities.DateToString(LocationData.Heading!.timestamp)
                AddressLabel.text = ""
                CoordinatesLabel.text = "Heading to \(HeadingString)"
            }
        }
        else
        {
            if LocationData.Location == nil
            {
                fatalError("LocationData.Location is nil in LoadData")
            }
            TimeLabel.text = Utilities.DateToString(LocationData.Location!.timestamp)
            CoordinatesLabel.text = Utilities.CoordinatesToString(Latitude: LocationData.Location!.coordinate.latitude,
                                                                  Longitude: LocationData.Location!.coordinate.longitude,
                                                                  Altitude: LocationData.Location!.altitude)
            AddressLabel.text = LocationData.DecodedAddress ?? ""
        }
    }
}
