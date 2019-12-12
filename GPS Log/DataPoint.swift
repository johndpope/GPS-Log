//
//  DataPoint.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

/// Contains a single location from a session. Once a session is ended, all data points are written to the database
/// and then cleared.
class DataPoint
{
    /// Delegate that is called when the data point is updated. This happens mostly when address data becomes
    /// available asynchronously.
    public weak var Delegate: DataPointUpdatedProtocol? = nil

    /// Initializer.
    /// - Parameter WithLocation: The location data from `CoreLocation`.
    /// - Parameter IsMarked: If true, the user requested a location determination for whatever reason. If false,
    ///                       the location is from a regularly scheduled location determination activity.
    /// - Parameter Delegate: The delegate called when the data point is updated asynchronously.
    /// - Parameter SkipAddress: If true, the address will not be searched for. This is provided as a way for
    ///                          reading back data points from the database that already have addresses so extra
    ///                          calls are not needed.
    init(WithLocation: CLLocation, IsMarked: Bool = false, Delegate: DataPointUpdatedProtocol? = nil,
         SkipAddress: Bool = false)
    {
        SkipGettingAddress = SkipAddress
        _IsHeadingChange = false
        self.Delegate = Delegate
        Location = WithLocation
        _IsMarked = IsMarked
    }
    
    var SkipGettingAddress: Bool = false
    
    /// Initializer.
    /// - Parameter WithHeading: A new heading as determined by `CoreLocation`.
    /// - Parameter Delegate: The delegate called when the data point is updated asynchronously.
    init(WithHeading: CLHeading, Delegate: DataPointUpdatedProtocol? = nil)
    {
        SkipGettingAddress = true
        self.Delegate = Delegate
        _Heading = WithHeading
        _IsHeadingChange = true
        _IsMarked = false
    }
    
    /// Initializer. Used for when reading heading changes from the database. We need to so this because CoreLocation does not
    /// allow creating new `CLHeading` classes with user-defined data.
    /// - Parameter WithNewHeading: New heading value.
    /// - Parameter TimeStamp: Heading change time stamp.
    init(WithNewHeading: Double, TimeStamp: Date)
    {
        SkipGettingAddress = true
        _HeadingValue = WithNewHeading
        _HeadingTimeStamp = TimeStamp
        _Heading = nil
        _IsHeadingChange = true
        _IsMarked = false
    }
    
    /// Holds the session ID.
    private var _SessionID: UUID = UUID()
    /// Get or set the ID of the session to which this data point belongs.
    public var SessionID: UUID
    {
        get
        {
            return _SessionID
        }
        set
        {
            _SessionID = newValue
        }
    }
    

    
    /// Holds the location of the data point.
    private var _Location: CLLocation? = nil
    /// Get or set the location of the data point. Assumed to be populated by `CoreLocation`.
    /// - Note: If the proper setting is true, the address of the location will determined (as best possible
    ///         given APIs and the like). This is an asynchronous process so while setting this property will
    ///         result in an almost immediate return, the closure in `GetAddressOf` will still be executed
    ///         sometime in the future. If `SkipGettingAddress` is true, the address is not searched for.
    public var Location: CLLocation?
    {
        get
        {
            return _Location
        }
        set
        {
            _Location = newValue
            if _Location != nil
            {
                MapPoint = Utilities.CoordinateToPoint(Latitude: _Location!.coordinate.latitude, Longitude: _Location!.coordinate.longitude)
                if SkipGettingAddress
                {
                    print("Skipping address decoding")
                }
                else
                {
                    GetAddressOf(_Location!)
                }
            }
        }
    }
    
    /// Attempts to determine the address of the passed location via reverse geocoding APIs.
    /// - Note: The address will be returned asynchronously and be handled in the closure for the `reverseGeocodeLocation`
    ///         call. After an address is available, `Delegate.HaveAddress` will be called to notify the delegate of
    ///         an updated address.
    /// - Parameter Location: The location for which the address will be determined.
    public func GetAddressOf(_ Location: CLLocation)
    {
        let Geocoder = CLGeocoder()
        Geocoder.reverseGeocodeLocation(_Location!)
        {
            PlaceMarks, Error in
            if PlaceMarks == nil
            {
                print("Error reverse geocoding: \(Error!.localizedDescription)")
                return
            }
            self.DecodedAddress = Utilities.ConstructAddress(From: PlaceMarks![0])
            self.Delegate?.HaveAddress(ThePoint: self, TheAddress: self.DecodedAddress!)
        }
    }
    
    /// Holds the marked status.
    private var _IsMarked: Bool = false
    /// Get or set the marked status. If this is true, the user told the caller to determine the location
    /// outside of the normal periodic determination cycle. If false (which is default), the data point is
    /// assumed to be a periodic location.
    public var IsMarked: Bool
    {
        get
        {
            return _IsMarked
        }
        set
        {
            _IsMarked = newValue
        }
    }
    
    /// Holds the decoded address when available.
    private var _DecodedAddress: String? = nil
    /// Get or set the decoded address from `GetAddressOf`. If no address is available, nil is returned.
    public var DecodedAddress: String?
    {
        get
        {
            return _DecodedAddress
        }
        set
        {
            _DecodedAddress = newValue
        }
    }
    
    /// Holds the written flag.
    private var _Written: Bool = false
    /// Get or set the flag indicating the data has been written to the database.
    public var Written: Bool
    {
        get
        {
            return _Written
        }
        set
        {
            _Written = newValue
        }
    }
    
    /// Holds the entry ID.
    private var _EntryID: UUID = UUID()
    /// Get or set the entry ID.
    public var EntryID: UUID
    {
        get
        {
            return _EntryID
        }
        set
        {
            _EntryID = newValue
        }
    }
    
    /// Holds the instance count. Starts at one for the first instance.
    private var _InstanceCount: Int = 1
    /// Get or set the instance count. This is the number of times a given location was recorded (in other words,
    /// if the user stays in one spot for a long time, this value will be large).
    public var InstanceCount: Int
    {
        get
        {
            return _InstanceCount
        }
        set
        {
            _InstanceCount = newValue
        }
    }
    
    /// Returns `EntryID` as an upper-cased string.
    public var EntryIDString: String
    {
        get
        {
            return _EntryID.uuidString.uppercased()
        }
    }
    
    /// Holds the heading changed flag.
    private var _IsHeadingChange: Bool = false
    /// Get or set the heading changed flag. If this value is true, most of the other fields in this class
    /// were not set and only `Heading` is valid.
    public var IsHeadingChange: Bool
    {
        get
        {
            return _IsHeadingChange
        }
        set
        {
            _IsHeadingChange = newValue
        }
    }
    
    /// Holds the heading value.
    public var _HeadingValue: Double = 0.0
    /// Get or set the heading value. If `IsHeadingChange` is true and `Heading` is nil, this property contains the heading
    /// value (and `HeadingTimeStamp` contains the timestamp of the heading change).
    public var HeadingValue: Double
    {
        get
        {
            return _HeadingValue
        }
        set
        {
            _HeadingValue = newValue
        }
    }
    
    /// Holds the heading changed time stamp.
    private var _HeadingTimeStamp: Date? = nil
    /// Get or set the heading changed time stamp. If `IsHeadingChange` is true and `Heading` is nil, this property contains the
    /// time stamp of the change (and `HeadingValue` contains the actual new heading).
    public var HeadingTimeStamp: Date?
    {
        get
        {
            return _HeadingTimeStamp
        }
        set
        {
            _HeadingTimeStamp = newValue
        }
    }
    
    /// Holds the heading for changed heading data points.
    private var _Heading: CLHeading? = nil
    /// Get or set the new heading. Used for when `CoreLocation` notifies us of a new heading.
    /// - Note: If `IsHeadingChange` is true and this property is nil, then the data in this class was read from a database and
    ///         heading data can be found in `HeadingValue` and `HeadingTimeStamp`.
    public var Heading: CLHeading?
    {
        get
        {
            return _Heading
        }
        set
        {
            _Heading = newValue
        }
    }
    
    /// Holds the map point for the coordinates.
    private var _MapPoint: CGPoint = CGPoint(x: 0, y: 0)
    /// Get or set the map point for the coordinates.
    public var MapPoint: CGPoint
    {
        get
        {
            return _MapPoint
        }
        set
        {
            _MapPoint = newValue
        }
    }
}
