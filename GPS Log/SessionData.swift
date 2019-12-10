//
//  SessionData.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/6/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Holds a single session's set of information.
class SessionData
{
    /// Default initializer.
    init()
    {
        Saved = false
    }
    
    /// Initializer. Most likely used when reading data from a database rather than when
    /// gathering data.
    /// - Parameter Name: The name of the session.
    /// - Parameter ID: The ID of the session.
    /// - Parameter Start: The starting time of the session.
    /// - Parameter End: The ending time of the session. If nil, no end time is available.
    init(Name: String, ID: UUID, Start: Date, End: Date? = nil)
    {
        _Name = Name
        _ID = ID
        _SessionStart = Start
        if End != nil
        {
            _SessionEnd = End!
        }
    }
    
    /// Holds the session's name.
    private var _Name: String = ""
    /// Get or set the session's name.
    public var Name: String
    {
        get
        {
            return _Name
        }
        set
        {
            _Name = newValue
        }
    }
    
    /// Holds the ID of the session.
    private var _ID: UUID = UUID()
    /// Get or set the ID of the session.
    public var ID: UUID
    {
        get
        {
            return _ID
        }
        set
        {
            _ID = newValue
        }
    }
    
    /// Holds the time the session started.
    private var _SessionStart: Date = Date()
    /// Get or set the session start time.
    public var SessionStart: Date
    {
        get
        {
            return _SessionStart
        }
        set
        {
            _SessionStart = newValue
        }
    }
    
    /// Holds the time the session ended.
    private var _SessionEnd: Date = Date()
    /// Get or set the session end time.
    public var SessionEnd: Date
    {
        get
        {
            return _SessionEnd
        }
        set
        {
            _SessionEnd = newValue
        }
    }
    
    /// Holds the saved flag.
    private var _Saved: Bool = false
    /// Get or set the saved flag indicating the session was saved to the database.
    public var Saved: Bool
    {
        get
        {
            return _Saved
        }
        set
        {
            _Saved = newValue
        }
    }
    
    /// Holds the set of locations for the session.
    private var _Locations: [DataPoint] = []
    /// Get or set the locations for the session.
    public var Locations: [DataPoint]
    {
        get
        {
            return _Locations
        }
        set
        {
            _Locations = newValue
        }
    }
}
