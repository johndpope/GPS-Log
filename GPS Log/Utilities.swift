//
//  Utilities.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/5/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import MapKit

/// General-purpose utilities.
class Utilities
{
    /// Pad the passed string with specified leading characters to make the string no longer
    /// than `ForCount` characters in length.
    /// - Parameter Value: The value to pre-pad.
    /// - Parameter WithLeading: The string (assumed to be one character long) to use to pad
    ///                          the beginning of `Value`.
    /// - Parameter ForCount: The final total length of the returned string. If `Value` is already
    ///                       this length or greater, it is returned unchanged.
    /// - Returns: Padded string.
    public static func Pad(_ Value: String, _ WithLeading: String, _ ForCount: Int) -> String
    {
        if Value.count >= ForCount
        {
            return Value
        }
        let Delta = ForCount - Value.count
        let Many = String(repeating: WithLeading, count: Delta)
        return Many + Value
    }
    
    /// Pad the passed string with specified leading characters to make the string no longer
    /// than `ForCount` characters in length.
    /// - Parameter Value: The value to pre-pad. Passed as an integer.
    /// - Parameter WithLeading: The string (assumed to be one character long) to use to pad
    ///                          the beginning of `Value`.
    /// - Parameter ForCount: The final total length of the returned string. If `Value` is already
    ///                       this length or greater, it is returned unchanged.
    /// - Returns: Padded string.
    public static func Pad(_ Value: Int, _ WithLeading: String, _ ForCount: Int) -> String
    {
        return Pad("\(Value)", WithLeading, ForCount)
    }
    
    /// Pad the passed string with specified trailing characters to make the string no longer
    /// than `ForCount` characters in length.
    /// - Parameter Value: The value to post-pad.
    /// - Parameter WithLeading: The string (assumed to be one character long) to use to pad
    ///                          the ending of `Value`.
    /// - Parameter ForCount: The final total length of the returned string. If `Value` is already
    ///                       this length or greater, it is returned unchanged.
    /// - Returns: Padded string.
    public static func Pad(_ Value: String, WithTrailing: String, ForCount: Int) -> String
    {
        if Value.count >= ForCount
        {
            return Value
        }
        let Delta = ForCount - Value.count
        let Many = String(repeating: WithTrailing, count: Delta)
        return Value + Many
    }
    
    /// Converts the passed date into a string.
    /// - Parameter ConvertMe: Date to convert.
    /// - Returns: String equivalent of `ConvertMe`.
    public static func DateToString(_ ConvertMe: Date) -> String
    {
        let Cal = Calendar.current
        let Hour = Cal.component(.hour, from: ConvertMe)
        let Minute = Cal.component(.minute, from: ConvertMe)
        let Second = Cal.component(.second, from: ConvertMe)
        let Year = Cal.component(.year, from: ConvertMe)
        let Month = Cal.component(.month, from: ConvertMe)
        let Day = Cal.component(.day, from: ConvertMe)
        return "\(Year)-\(Pad(Month, "0", 2))-\(Pad(Day, "0", 2)) \(Pad(Hour, "0", 2)):\(Pad(Minute, "0", 2)):\(Pad(Second, "0", 2))"
    }
    
    /// Converts a string date (serialized with `DateToString`) into a `Date` object.
    /// - Parameter ConvertMe: String to convert into a date.
    /// - Returns: `Date` equivalent of the passed string on success, nil on parse failure.
    public static func StringToDate(_ ConvertMe: String) -> Date?
    {
        if ConvertMe.isEmpty
        {
            return nil
        }
        let Parts = ConvertMe.split(separator: " ", omittingEmptySubsequences: true)
        if Parts.count != 2
        {
            return nil
        }
        let DatePart = String(Parts[0])
        let TimePart = String(Parts[1])
        let DateParts = DatePart.split(separator: "-", omittingEmptySubsequences: true)
        if DateParts.count != 3
        {
            return nil
        }
        var Year = 0
        var Month = 0
        var Day = 0
        if let temp = Int(String(DateParts[0]))
        {
            Year = temp
        }
        if let temp = Int(String(DateParts[1]))
        {
            Month = temp
        }
        if let temp = Int(String(DateParts[2]))
        {
            Day = temp
        }
        let TimeParts = TimePart.split(separator: ":", omittingEmptySubsequences: true)
        if TimeParts.count != 3
        {
            return nil
        }
        var Hour = 0
        var Minute = 0
        var Second = 0
        if let temp = Int(String(TimeParts[0]))
        {
            Hour = temp
        }
        if let temp = Int(String(TimeParts[1]))
        {
            Minute = temp
        }
        if let temp = Int(String(TimeParts[2]))
        {
            Second = temp
        }
        var Comp = DateComponents()
        Comp.year = Year
        Comp.month = Month
        Comp.day = Day
        Comp.hour = Hour
        Comp.minute = Minute
        Comp.second = Second
        let Cal = Calendar.current
        let FinalDate = Cal.date(from: Comp)
        return FinalDate
    }
    
    /// Create a string representation of the passed double with the supplied precision. No rounding
    /// takes place here (despite the name of the function) - only truncation of the string occurs.
    /// - Parameter Value: The value to be converted to a string then truncated.
    /// - Parameter Precision: The number of fractional digits.
    /// - Returns: Truncated string value based on `Value`.
    public static func RoundedString(Value: Double, Precision: Int = 3) -> String
    {
        let stemp = "\(Value)"
        let Parts = stemp.split(separator: ".", omittingEmptySubsequences: true)
        if Parts.count == 1
        {
            return stemp
        }
        if Parts.count != 2
        {
            fatalError("Too many parts!")
        }
        var Least = String(Parts[1])
        Least = String(Least.prefix(Precision))
        return String(Parts[0]) + "." + Least
    }
    
    /// Converted coordinate data to a string.
    /// - Parameter Latitude: The latitude value.
    /// - Parameter Longitude: The longitude value.
    /// - Parameter Altitude: The altitude. If nil, no altitude will be included.
    /// - Parameter ShowOrdinalDirections: If true, all numbers will be positive and the appropriate
    ///                                    "N", "S", "E", or "W" labels will be appended to the strings.
    ///                                    If false, the sign of the value will indicate which quadrant
    ///                                    the coordinate is in.
    /// - Returns: String representation of the passed coordinates.
    public static func CoordinatesToString(Latitude: CLLocationDegrees, Longitude: CLLocationDegrees,
                                           Altitude: CLLocationDistance? = nil,
                                           ShowOrdinalDirections: Bool = false) -> String
    {
        let WorkingLatitude = ShowOrdinalDirections ? abs(Latitude) : Latitude
        let WorkingLongitude = ShowOrdinalDirections ? abs(Longitude) : Longitude
        var Lat = RoundedString(Value: WorkingLatitude)
        var Lon = RoundedString(Value: WorkingLongitude)
        if ShowOrdinalDirections
        {
            Lat = Lat + String(Latitude >= 0.0 ? "N" : "S")
            Lon = Lon + String(Longitude >= 0.0 ? "E" : "W")
        }
        var AltVal = ""
        if let Alt = Altitude
        {
            AltVal = ", " + RoundedString(Value: Alt) + "m"
        }
        return "\(Lat),\(Lon)\(AltVal)"
    }
    
    /// Given the passed placemark, create an address string.
    /// - Note: The Apple API that creates the address is throttled to one address a minute (although when
    ///         there is low demand, it is entirely possible to get one a second).
    /// - Parameter From: The placemark from the system.
    /// - Returns: Address constructed from the placemark.
    public static func ConstructAddress(From: CLPlacemark) -> String
    {
        var Address = ""
        if let Name = From.name
        {
            Address.append(Name + "\n")
        }
        if let Country = From.country
        {
            Address.append(Country + " ")
        }
        if let PostCode = From.postalCode
        {
            Address.append(PostCode + " ")
        }
        if let Administrative = From.administrativeArea
        {
            Address.append(Administrative + " ")
        }
        if !Address.isEmpty
        {
            Address.append("\n")
        }
        var AddedLine2 = false
        if let SubAdministrative = From.subAdministrativeArea
        {
            AddedLine2 = true
            Address.append(SubAdministrative + " ")
        }
        if let Locality = From.locality
        {
            AddedLine2 = true
            Address.append(Locality + " ")
        }
        if let SubLocality = From.subLocality
        {
            AddedLine2 = true
            Address.append(SubLocality + " ")
        }
        if AddedLine2
        {
            Address.append("\n")
        }
        if let Thoroughfare = From.thoroughfare
        {
            Address.append(Thoroughfare + " ")
        }
        if let SubThoroughfare = From.subThoroughfare
        {
            Address.append(SubThoroughfare + " ")
        }
        if let TimeZone = From.timeZone
        {
            Address.append(TimeZone.abbreviation()!)
        }
        return Address
    }
    
    /// Calculate the length of a given line of latitude on the Earth, asuming (incorrectly) the Earth is
    /// a perfect sphere. For our purposes, it is.
    /// - Note: See [Calculate length of latitude line.](https://boards.straightdope.com/sdmb/showthread.php?t=680496)
    /// - Parameter Angle: The latitude value in degrees. Negative (eg, southern) latitudes will return positive
    ///                    distances.
    /// - Returns: Length of line of latitude at given angle measure in degress. Returned length is in kilometers.
    public static func LengthOfLatitude(_ Angle: Double) -> Double
    {
        return cos(abs(Angle) * Double.pi / 180.0) * 40075.017
    }
    
    /// Given an angle and radius, return the length of the arc. This function is
    /// intended to be used to calculate coordinates on Earth. Given the Earth is
    /// not perfectly spherical, this function is slightly inaccurate.
    /// - Note: See [Find Arc Length](https://www.wikihow.com/Find-Arc-Length)
    /// - Parameter Angle: Angle (in degrees) that describes the arc.
    /// - Parameter Radius: The radius of the circle. Defaults to the mean radius of
    ///                     the Earth (6371.0 km).
    /// - Returns: The length of the arc described by the passed angle and radius.
    public static func ArcLength(_ Angle: Double, _ Radius: Double = 6371.0) -> Double
    {
        return 2.0 * Double.pi * Radius * (Angle / 180.0)//360.0)
    }
    
    /// Given a latitude and longitude, return a `CGPoint` suitable for plotting locations.
    /// - Note: This function (and the functions it calls) treats the Earth as a perfect sphere.
    /// - Warning: Do not use this function for critical conversions.
    /// - Parameter Latitude: The angle of latitude (in degrees). Positive values are in the northern hemisphere,
    ///                       negative values in the southern hemisphere. In other words, values should be clamped
    ///                       to -180.0 to 180.0.
    /// - Parameter Longitude: The angle of longitude (in degrees). Positive values are in the eastern hemisphere,
    ///                        negative values in the western hemisphere. In other words, values should be clamped
    ///                        to -90.0 to 90.0
    /// - Returns: `CGPoint` equivalent of the passed latitude and longitude.
    public static func CoordinateToPoint(Latitude: Double, Longitude: Double) -> CGPoint
    {
        //Get Y
        let Y = ArcLength(Longitude) * 0.5
        //Get X
        let LatitudeCircle = LengthOfLatitude(Latitude)
        let X = (LatitudeCircle) * (Latitude / 180.0)
        return CGPoint(x: X, y: Y)
    }
}
