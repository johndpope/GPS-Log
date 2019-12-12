//
//  IPoint.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/12/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

/// Class-based representation of a point backed by double values.
class IPoint: CustomStringConvertible, Equatable, Comparable
{
    /// Default initialier. `X` and `Y` both default to 0.0.
    init()
    {
        _X = 0.0
        _Y = 0.0
    }
    
    /// Initializer.
    /// - Parameter Location: A CoreLocation 2D coordinate used as the source for `X` and `Y`. The `longitude` field is used
    ///                       for `X` and `latitude` field for `Y`.
    init(_ Location: CLLocationCoordinate2D)
    {
        _X = Location.longitude
        _Y = Location.latitude
    }
    
    /// Initializer.
    /// - Parameter Ancillary: The ancillary point.
    init(_ Ancillary: IPoint)
    {
        _AncillaryPoint = Ancillary
    }
    
    /// Initializer.
    /// - Parameter X: Initial `X` value.
    /// - Parameter Y: Initial `Y` value.
    init(_ X: Double, _ Y: Double)
    {
        _X = X
        _Y = Y
    }
    
    /// Initializer.
    /// - Parameter X: Initial `X` value. Converted to Double.
    /// - Parameter Y: Initial `Y` value. Converted to Double.
    init(_ X: Int, _ Y: Int)
    {
        _X = Double(X)
        _Y = Double(Y)
    }
    
    /// Initializer.
    /// - Parameter X: Initial `X` value. Converted to Double.
    /// - Parameter Y: Initial `Y` value. Converted to Double.
    init(_ X: CGFloat, _ Y: CGFloat)
    {
        _X = Double(X)
        _Y = Double(Y)
    }
    
    /// Initializer.
    /// - Parameter Raw: Raw string to convert into an IPoint. The string must be in the format *X value*,*Y value* where each
    ///                  value can be converted individually into a Double value. Nil is returned on parsing or conversion errors.
    init?(_ Raw: String)
    {
        if Raw.isEmpty
        {
            return nil
        }
        let Parts = Raw.split(separator: ",", omittingEmptySubsequences: true)
        if Parts.count != 2
        {
            return nil
        }
        let RawX = String(Parts[0])
        let RawY = String(Parts[1])
        if let ConvertedX = Double(RawX)
        {
            if let ConvertedY = Double(RawY)
            {
                _X = ConvertedX
                _Y = ConvertedY
            }
            else
            {
                return nil
            }
        }
        else
        {
            return nil
        }
    }
    
    /// Holds the X value.
    private var _X: Double = 0.0
    
    /// Holds the Y value.
    private var _Y: Double = 0.0
    
    /// Get or set the X value.
    public var X: Double
    {
        get
        {
            return _X
        }
        set
        {
            _X = newValue
        }
    }
    
    /// Get or set the Y value.
    public var Y: Double
    {
        get
        {
            return _Y
        }
        set
        {
            _Y = newValue
        }
    }
    
    /// Holds the ancillary point.
    private var _AncillaryPoint: IPoint? = nil
    /// Get or set the ancillary point.
    public var AncillaryPoint: IPoint?
    {
        get
        {
            return _AncillaryPoint
        }
        set
        {
            _AncillaryPoint = newValue
        }
    }
    
    /// Test the current value of `X` against the `X` value in the passed point. If the passed point's `X` value is less than
    /// the current instance `X` value, update the instance and store the passed point in the `AncillaryPoint` property.
    public func UpdateXIfLessThan(_ TestPoint: IPoint)
    {
        if TestPoint.X < _X
        {
            _X = TestPoint.X
            _AncillaryPoint = TestPoint
        }
    }
    
    /// Test the current value of `X` against the `X` value in the passed point. If the passed point's `X` value is greater than
    /// the current instance `X` value, update the instance and store the passed point in the `AncillaryPoint` property.
    public func UpdateXIfGreaterThan(_ TestPoint: IPoint)
    {
        if TestPoint.X > _X
        {
            _X = TestPoint.X
            _AncillaryPoint = TestPoint
        }
    }
    
    /// Test the current value of `Y` against the `Y` value in the passed point. If the passed point's `Y` value is less than
    /// the current instance `Y` value, update the instance and store the passed point in the `AncillaryPoint` property.
    public func UpdateYIfLessThan(_ TestPoint: IPoint)
    {
        if TestPoint.Y < _Y
        {
            _Y = TestPoint.Y
            _AncillaryPoint = TestPoint
        }
    }
    
    /// Test the current value of `Y` against the `Y` value in the passed point. If the passed point's `Y` value is greater than
    /// the current instance `Y` value, update the instance and store the passed point in the `AncillaryPoint` property.
    public func UpdateYIfGreaterThan(_ TestPoint: IPoint)
    {
        if TestPoint.Y > _Y
        {
            _Y = TestPoint.Y
            _AncillaryPoint = TestPoint
        }
    }
    
    /// Set `X` to the passed value if `X` has a different value.
    /// - Parameter TestX: The value to test against `X` for inequality.
    public func UpdateXIfNotEqual(_ TestX: Double)
    {
        if TestX != _X
        {
            _X = TestX
        }
    }
    
    /// Set `X` to the passed value if the passed value is less than the current value of `X`.
    /// - Parameter TestX: The value to test against `X`.
    public func UpdateXIfLessThan(_ TestX: Double)
    {
        if TestX < _X
        {
            _X = TestX
        }
    }
    
    /// Set `X` to the passed value if the passed value is greater than the current value of `X`.
    /// - Parameter TestX: The value to test against `X`.
    public func UpdateXIfGreaterThan(_ TestX: Double)
    {
        if TestX > _X
        {
            _X = TestX
        }
    }
    
    /// Set `Y` to the passed value if `Y` has a different value.
    /// - Parameter TestY: The value to test against `Y` for inequality.
    public func UpdateYIfNotEqual(_ TestY: Double)
    {
        if TestY != _Y
        {
            _Y = TestY
        }
    }
    
    /// Set `Y` to the passed value if the passed value is less than the current value of `Y`.
    /// - Parameter TestY: The value to test against `Y`.
    public func UpdateYIfLessThan(_ TestY: Double)
    {
        if TestY < _Y
        {
            _Y = TestY
        }
    }
    
    /// Set `Y` to the passed value if the passed value is greater than the current value of `Y`.
    /// - Parameter TestY: The value to test against `Y`.
    public func UpdateYIfGreaterThan(_ TestY: Double)
    {
        if TestY > _Y
        {
            _Y = TestY
        }
    }
    
    /// Returns the distance from this instance to the passed point.
    /// - Parameter OtherPoint: The other point used to calculate the distance.
    /// - Returns: Unit-less distance between this point and the passed point.
    public func DistanceTo(_ OtherPoint: IPoint) -> Double
    {
        return IPoint.DistanceBetween(From: self, To: OtherPoint)
    }
    
    /// Returns the distance from this instance to the passed point.
    /// - Parameter X: X value of the other point.
    /// - Parameter Y: Y value of the other point.
    /// - Returns: Unit-less distance between this point and the passed point.
    public func DistanceTo(_ X: Double, _ Y: Double) -> Double
    {
        return DistanceTo(IPoint(X, Y))
    }
    
    /// Returns a string description of the point.
    var description: String
    {
        return "\(_X),\(_Y)"
    }
    
    // MARK: - Static class functions.
    
    /// Calculate the (unit-less) distance between the two passed points.
    /// - Parameter From: First point.
    /// - Parameter To: Second point.
    /// - Returns: Unit-less distance between `From` and `To`.
    public static func DistanceBetween(From: IPoint, To: IPoint) -> Double
    {
        var XDelta = From._X - To._X
        XDelta = XDelta * XDelta
        var YDelta = From._Y - To._Y
        YDelta = YDelta * YDelta
        return sqrt(XDelta + YDelta)
    }
    
    /// Calculate the (unit-less) distance between two passed points.
    /// - Parameter Point1: First point.
    /// - Parameter X: X value of second point.
    /// - Parameter Y: Y value of second point.
    /// - Returns: Unit-less distance between the two points.
    public static func DistanceBetween(Point1: IPoint, X: Double, Y: Double) -> Double
    {
        return DistanceBetween(From: Point1, To: IPoint(X, Y))
    }
    
    /// Compares two points for equality. Equality means `X` is the same for both points, and `Y` is the same for both points.
    /// - Returns: True if both points are equal, false if not.
    static func == (lhs: IPoint, rhs: IPoint) -> Bool
    {
        return lhs._X == rhs._X && lhs._Y == rhs._Y
    }
    
    /// Compares two points for inequality. Point inequality is calculated by the distance from the origin.
    /// - Returns: True, if `lhs` is less than `rhs`, false otherwise.
    static func < (lhs: IPoint, rhs: IPoint) -> Bool
    {
        let LeftOriginDistance = IPoint.DistanceBetween(Point1: lhs, X: 0.0, Y: 0.0)
        let RightOriginDistance = IPoint.DistanceBetween(Point1: rhs, X: 0.0, Y: 0.0)
        return LeftOriginDistance < RightOriginDistance
    }
}
