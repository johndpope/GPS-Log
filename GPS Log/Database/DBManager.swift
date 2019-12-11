//
//  DBManager.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/6/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import SQLite3
import CoreLocation

/// Manages data to and from the Sqlite 3 database.
/// - Note:
///   - The database for this app stores most things in two tables:
///     1. **Sessions** which holds data on recording sessions.
///     2. **Entries** which holds entries for sessions.
class DBManager
{
    /// Verifies the database is in the expected location. If the database is not in the proper location, a new one is created
    /// from the template database in the read-only resources from the application.
    /// - Parameter Name: The name of the database. Must include the extension.
    public static func VerifyDatabase(_ Name: String) 
    {
        //First, see if the database is already available in the documents directory.
        let DocumentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard DocumentURL.count != 0 else
        {
            print("No document directory URLs returned.")
            return
        }
        let DestURL = DocumentURL.first!.appendingPathComponent(Name)
        var FoundDB = false
        do
        {
            FoundDB = try DestURL.checkResourceIsReachable()
        }
        catch
        {
            FoundDB = false
        }
        if !FoundDB
        {
            let SourceURL = Bundle.main.resourceURL?.appendingPathComponent(Name)
            do
            {
                try FileManager.default.copyItem(atPath: SourceURL!.path, toPath: DestURL.path)
            }
            catch
            {
                print("Error when attempting to copy database: \(error.localizedDescription)")
            }
        }
    }
    
    /// Gets the URL of the named database.
    /// - Parameter Name: Full name (but no path) of the database.
    /// - Returns: The URL of the database. Nil if `Name` is empty of the database cannot be found.
    public static func GetDatabaseURL(_ Name: String) -> URL?
    {
        if Name.isEmpty
        {
            return nil
        }
        if let DirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        {
            let DBURL = DirURL.appendingPathComponent(Name)
            return DBURL
        }
        return nil
    }
    
    /// Returns a database handle (`OpaquePoint` type) for the database whose name is passed to use. The name of the database
    /// must include the extension if the name on local storage has an extension.
    /// - Note: This function assumes the database resides in the documents directory.
    /// - Parameter Name: The name of the database.
    /// - Returns: Handle to the named database.
    public static func GetDatabaseHandle(_ Name: String) -> OpaquePointer?
    {
        if let DBURL = GetDatabaseURL(Name)
        {
            var Handle: OpaquePointer? = nil
            if sqlite3_open(DBURL.path, &Handle) != SQLITE_OK
            {
                LastSQLErrorCode = sqlite3_errcode(Handle)
                LastSQLErrorMessage = String(cString: sqlite3_errmsg(Handle))
                print("Error getting handle for \(Name): \n  >> \(LastSQLErrorMessage)")
                return nil
            }
            else
            {
                return Handle
            }
        }
        else
        {
            return nil
        }
    }
    
    /// Replace all new line characters with the specified character.
    /// - Parameter In: The source string.
    /// - Parameter With: The character (in String format) to replace all new line characters.
    /// - Returns: New string with all new lines replaced by `With`.
    public static func ReplaceNewLines(In: String, With: String) -> String
    {
        var Updated = In
            Updated = Updated.replacingOccurrences(of: "\n", with: ",")
        return Updated
    }
    
    /// Update a given data point's information.
    /// - Note: The following fields will be updated:
    ///   - **Address** If `DecodedAddress` in the passed data point is nil, it will not be updated.
    ///   - **InstanceCount** Instance count for the point.
    /// - Parameter DB: Handle to the database.
    /// - Parameter Point: The point to update.
    public static func UpdateLocation(DB: OpaquePointer?, _ Point: DataPoint)
    {
        if DB == nil
        {
            fatalError("Database handle in UpdateLocation is nil.")
        }
        if Point.DecodedAddress == nil
        {
            fatalError("Nil address in UpdateLocation.")
        }
        let TableName = "Entries"
        let ID = Point.EntryIDString
        
        var Update = "UPDATE \(TableName) SET "
        if let PointAddress = Point.DecodedAddress
        {
            let FinalAddress = ReplaceNewLines(In: PointAddress, With: ",")
        Update.append("Address = '\(FinalAddress)'")
        }
        if Point.DecodedAddress != nil
        {
            Update.append(", ")
        }
        Update.append("InstanceCount = \(Point.InstanceCount) ")
        Update.append("WHERE EntryID = '\(ID)';")
        var UpdateHandle: OpaquePointer? = nil
        if sqlite3_prepare_v2(DB, Update, -1, &UpdateHandle, nil) != SQLITE_OK
        {
            print("Error preparing: \(Update)")
            LastSQLErrorCode = sqlite3_errcode(DB)
            LastSQLErrorMessage = String(cString: sqlite3_errmsg(DB))
            print("  \(LastSQLErrorMessage)")
        }
        if sqlite3_step(UpdateHandle) != SQLITE_DONE
        {
            print("Error updating with \(Update)")
            LastSQLErrorCode = sqlite3_errcode(DB)
            LastSQLErrorMessage = String(cString: sqlite3_errmsg(DB))
                        print("  \(LastSQLErrorMessage)")
        }
        sqlite3_finalize(UpdateHandle)
    }
    
    /// Creates a Sqlite column list.
    /// - Parameter Names: Names to add to the list.
    /// - Returns: String in the format `({name1}, {name2}...)`.
    private static func MakeColumnList(_ Names: [String]) -> String
    {
        var List = "("
        for Index in 0 ..< Names.count
        {
            List.append(Names[Index])
            if Index < Names.count - 1
            {
                List.append(", ")
            }
        }
        List.append(")")
        return List
    }
    
    /// Write a single data point to the `Entries` table.
    /// - Note: **If DB is nil, a fatal error is generated.**
    /// - Parameter DB: Handle to the database to which we will write.
    /// - Parameter TrackData: The data to write.
    /// - Returns: True on success, false on failure.
    @discardableResult public static func WriteDataPoint(DB: OpaquePointer?, TrackData: DataPoint) -> Bool
    {
        if DB == nil
        {
            fatalError("Database handle in WriteDataPoint is nil.")
        }
        let TableName = "Entries"
        let ColumnList = MakeColumnList(["Session","Latitude","Longitude","Altitude","HorizontalAccuracy","VerticalAccuracy","TimeStamp","Speed",
                                         "Course","Address","Marked","EntryID","InstanceCount","Heading","IsHeadingChanged","HeadingTimeStamp"])
        var Update = "INSERT INTO \(TableName)\(ColumnList) VALUES("
        Update.append("'\(TrackData.SessionID.uuidString)', ")
        if !TrackData.IsHeadingChange
        {
            Update.append("'\(TrackData.Location!.coordinate.latitude)', ")
            Update.append("'\(TrackData.Location!.coordinate.longitude)', ")
            Update.append("'\(TrackData.Location!.altitude)', ")
            Update.append("'\(TrackData.Location!.horizontalAccuracy)', ")
            Update.append("'\(TrackData.Location!.verticalAccuracy)', ")
            Update.append("'\(Utilities.DateToString(TrackData.Location!.timestamp))', ")
            Update.append("'\(TrackData.Location!.speed)', ")
            Update.append("'\(TrackData.Location!.course)', ")
            if TrackData.DecodedAddress == nil
            {
                Update.append("'n/a', ")
            }
            else
            {
                Update.append("'\(ReplaceNewLines(In: TrackData.DecodedAddress!, With: ","))', ")
            }
            Update.append("'\(TrackData.IsMarked)', ")
        }
        else
        {
            Update.append("'0', '0', '0', '0', '0', '1901-01-01 00:00:00', '0', '0', 'n/a', 'false', ")
        }
        Update.append("'\(TrackData.EntryIDString)', ")
        Update.append("\(TrackData.InstanceCount), ")
        
        var FinalHeadingTimeStamp = Date()
        if TrackData.IsHeadingChange
        {
            if TrackData.Heading == nil
            {
                //Use derived data.
                FinalHeadingTimeStamp = TrackData.HeadingTimeStamp!
                Update.append("\(TrackData.HeadingValue), ")
            }
            else
            {
                FinalHeadingTimeStamp = TrackData.Heading!.timestamp
                Update.append("\(TrackData.Heading!.trueHeading), ")
            }
            let HeadingChanged = Int(TrackData.IsHeadingChange ? 1 : 0)
            Update.append("\(HeadingChanged), ")
            
        }
        else
        {
            Update.append("0.0, 0, ")
        }
        Update.append("'\(Utilities.DateToString(FinalHeadingTimeStamp))'")
        Update.append(")")
        var InsertHandle: OpaquePointer? = nil
        if sqlite3_prepare_v2(DB, Update, -1, &InsertHandle, nil) != SQLITE_OK
        {
            print("Error preparing: \(Update)")
            return false
        }
        let Result = sqlite3_step(InsertHandle)
        if Result != SQLITE_DONE
        {
            print("Error running: \(Update)")
            return false
        }
        return true
    }
    
    /// Write one session's data to the `Sessions` table.
    /// - Note: **A fatal error is generated if DB is nil.**
    /// - Parameter DB: The handle to the database. If nil, a fatal error is generated.
    /// - Parameter SessionID: The ID of the session.
    /// - Parameter StartTime: The starting time of the session.
    /// - Parameter EndTime: The ending time of the session.
    /// - Parameter SessionName: The name of the session.
    /// - Returns: True on success, false on failure.
    @discardableResult public static func WriteSession(DB: OpaquePointer?, SessionID: UUID, StartTime: Date, EndTime: Date, SessionName: String) -> Bool
    {
        if DB == nil
        {
            fatalError("Database handle in WriteSession is nil.")
        }
        let TableName = "Sessions"
        let ID = SessionID.uuidString
        let Start = Utilities.DateToString(StartTime)
        let End = Utilities.DateToString(EndTime)
        
        var Update = "INSERT INTO \(TableName)(ID, StartTime, EndTime, Name) VALUES("
        Update.append("'\(ID)', ")
        Update.append("'\(Start)', ")
        Update.append("'\(End)', ")
        Update.append("'\(SessionName)'")
        Update.append(")")
        var InsertHandle: OpaquePointer? = nil
        if sqlite3_prepare_v2(DB, Update, -1, &InsertHandle, nil) != SQLITE_OK
        {
            print("Error preparing: \(Update)")
            return false
        }
        let Result = sqlite3_step(InsertHandle)
        if Result != SQLITE_DONE
        {
            print("Error running: \(Update)")
            return false
        }
        return true
    }
    
    /// Write a session end date and name.
    /// - Note: If `DB` is nil, a fatal error is generated.
    /// - Parameter DB: The database handle.
    /// - Parameter SessionID: The ID of the session to write.
    /// - Parameter EndDate: The end date of the session to write.
    /// - Parameter Name: The name of the session to write.
    /// - Returns: True on success, false on failure.
    @discardableResult public static func WriteDateAndName(DB: OpaquePointer?, SessionID: UUID, EndDate: Date, Name: String) -> Bool
    {
        if DB == nil
        {
            fatalError("Database handle in WriteDateAndName is nil.")
        }
        let TableName = "Sessions"
        let ID = SessionID.uuidString
        let End = Utilities.DateToString(EndDate)
        var Update = "UPDATE \(TableName) SET "
        Update.append("EndTime = '\(End)', Name = '\(Name)' ")
        Update.append("WHERE ID = '\(ID)';")
        var UpdateHandle: OpaquePointer? = nil
        if sqlite3_prepare_v2(DB, Update, -1, &UpdateHandle, nil) != SQLITE_OK
        {
            print("Error preparing: \(Update)")
            return false
        }
        if sqlite3_step(UpdateHandle) != SQLITE_DONE
        {
            print("Error updating with \(Update)")
            return false
        }
        sqlite3_finalize(UpdateHandle)
        return true
    }
    
    /// Set up a query in to the database.
    /// - Parameter DB: The handle of the database for the query.
    /// - Parameter Query: The query string.
    /// - Returns: Handle for the query. Valid only for the same database the query was generated for.
    public static func SetupQuery(DB: OpaquePointer?, Query: String) -> OpaquePointer?
    {
        if DB == nil
        {
            return nil
        }
        if Query.isEmpty
        {
            return nil
        }
        var QueryHandle: OpaquePointer? = nil
        if sqlite3_prepare(DB, Query, -1, &QueryHandle, nil) != SQLITE_OK
        {
            LastSQLErrorCode = sqlite3_errcode(DB)
            LastSQLErrorMessage = String(cString: sqlite3_errmsg(DB))
            print("Error preparing query \"\(Query)\": \(LastSQLErrorMessage)")
            return nil
        }
        return QueryHandle
    }
    
    /// Creates a syntactically correct XML key-value pair for the passed data.
    /// - Parameter Key: The key name.
    /// - Parameter Value: The value for the passed `Key`.
    /// - Parameter AppendSpace: If true, a space is added to the end of the string before it is returned.
    /// - Returns: XML-style key-value pair.
    public static func MakeXMLKVP(_ Key: String, _ Value: String, AppendSpace: Bool = true) -> String
    {
        var KVP = "Key=\"\(Value)\""
        if AppendSpace
        {
            KVP.append(" ")
        }
        return KVP
    }
    
    /// Returns a list of all data points for the passed `SessionID`. Data returned in XML format.
    /// - Parameter DB: The handle to the database. If nil, an empty array is returned.
    /// - Parameter SessionID: The ID of the session whose data will be returned.
    /// - Returns: List of strings, each an XML node for a given data point. Empty array on error.
    public static func GetSessionDataAsXML(DB: OpaquePointer?, SessionID: UUID) -> [String]
    {
        if DB == nil
        {
            return []
        }
        var Results = [String]()
        let TableName = "Entries"
        let ID = SessionID.uuidString
        let GetSQL = "SELECT * FROM \(TableName) WHERE SESSION='\(ID)'"
        let QueryHandle = SetupQuery(DB: DB, Query: GetSQL)
        while (sqlite3_step(QueryHandle) == SQLITE_ROW)
        {
            let SessionColumn = String(cString: sqlite3_column_text(QueryHandle, 1))
            let LatitudeColumn = String(cString: sqlite3_column_text(QueryHandle, 2))
            let LongitudeColumn = String(cString: sqlite3_column_text(QueryHandle, 3))
            let AltitudeColumn = String(cString: sqlite3_column_text(QueryHandle, 4))
            let HorizontalAccuracyColumn = String(cString: sqlite3_column_text(QueryHandle, 5))
            let VerticalAccuracyColumn = String(cString: sqlite3_column_text(QueryHandle, 6))
            let TimeStampColumn = String(cString: sqlite3_column_text(QueryHandle, 7))
            let SpeedColumn = String(cString: sqlite3_column_text(QueryHandle, 8))
            let CourseColumn = String(cString: sqlite3_column_text(QueryHandle, 9))
            let AddressColumn = String(cString: sqlite3_column_text(QueryHandle, 10))
            let MarkedColumn = String(cString: sqlite3_column_text(QueryHandle, 11))
            let EntryIDColumn = String(cString: sqlite3_column_text(QueryHandle, 12))
            let InstanceColumn = Int(sqlite3_column_int(QueryHandle, 13))
            let HeadingColumn = sqlite3_column_double(QueryHandle, 14)
            let IsHeadingColumn = Int(sqlite3_column_int(QueryHandle, 15))
            let HeadingTimeColumn = String(cString: sqlite3_column_text(QueryHandle, 16))
            var Line = "  <DataPoint "
            Line.append(MakeXMLKVP("SessionID", SessionColumn))
            Line.append(MakeXMLKVP("Latitude", LatitudeColumn))
            Line.append(MakeXMLKVP("Longitude", LongitudeColumn))
            Line.append(MakeXMLKVP("Altitude", AltitudeColumn))
            Line.append(MakeXMLKVP("HorizontalAccuracy", HorizontalAccuracyColumn))
            Line.append(MakeXMLKVP("VerticalAccuracy", VerticalAccuracyColumn))
            Line.append(MakeXMLKVP("TimeStamp", TimeStampColumn))
            Line.append(MakeXMLKVP("Speed", SpeedColumn))
            Line.append(MakeXMLKVP("Course", CourseColumn))
            Line.append(MakeXMLKVP("Address", AddressColumn))
            Line.append(MakeXMLKVP("Marked", MarkedColumn))
            Line.append(MakeXMLKVP("EntryID", EntryIDColumn.uppercased()))
            Line.append(MakeXMLKVP("InstanceCount", "\(InstanceColumn)"))
            let HeadingChanged = !(IsHeadingColumn == 0)
            let HeadingValue = HeadingChanged ? "\(HeadingColumn)" : ""
            Line.append(MakeXMLKVP("Heading", HeadingValue))
            Line.append(MakeXMLKVP("HeadingChanged", "\(HeadingChanged)"))
            Line.append(MakeXMLKVP("HeadingTimeStamp", "\(HeadingTimeColumn)", AppendSpace: false))
            Line.append("/>")
            Results.append(Line)
        }
        return Results
    }
    
    /// Returns a list of all data points for the passed `SessionID`. Data returned as an array of `DataPoint`s.
    /// - Note: Data point classes can represent a location or a heading change. Depending on the value of certain flags in
    ///         the database, the returned `DataPoint` may contain either a heading change or a location (but not both).
    /// - Parameter DB: The handle to the database. If nil, an empty array is returned.
    /// - Parameter SessionID: The ID of the session whose data will be returned.
    /// - Parameter UseTestData: If true, use test data.
    /// - Returns: Array of `DataPoint`s for the session. Empty array on error.
    public static func GetSessionData(DB: OpaquePointer?, SessionID: UUID, UseTestData: Bool = false) -> [DataPoint]
    {
        if DB == nil
        {
            return []
        }
        var Results = [DataPoint]()
        let TableName = UseTestData ? "TestEntries" : "Entries"
        let ID = SessionID.uuidString.uppercased()
        let GetSQL = "SELECT * FROM \(TableName) WHERE SESSION='\(ID)'"
        let QueryHandle = SetupQuery(DB: DB, Query: GetSQL)
        while (sqlite3_step(QueryHandle) == SQLITE_ROW)
        {
            let SessionColumn = String(cString: sqlite3_column_text(QueryHandle, 1))
            let LatitudeColumn = String(cString: sqlite3_column_text(QueryHandle, 2))
            let LongitudeColumn = String(cString: sqlite3_column_text(QueryHandle, 3))
            let AltitudeColumn = String(cString: sqlite3_column_text(QueryHandle, 4))
            let HorizontalAccuracyColumn = String(cString: sqlite3_column_text(QueryHandle, 5))
            let VerticalAccuracyColumn = String(cString: sqlite3_column_text(QueryHandle, 6))
            let TimeStampColumn = String(cString: sqlite3_column_text(QueryHandle, 7))
            let SpeedColumn = String(cString: sqlite3_column_text(QueryHandle, 8))
            let CourseColumn = String(cString: sqlite3_column_text(QueryHandle, 9))
            let AddressColumn = String(cString: sqlite3_column_text(QueryHandle, 10))
            let MarkedColumn = String(cString: sqlite3_column_text(QueryHandle, 11))
            let EntryIDColumn = String(cString: sqlite3_column_text(QueryHandle, 12))
            let InstanceColumn = Int(sqlite3_column_int(QueryHandle, 13))
            let HeadingColumn = sqlite3_column_double(QueryHandle, 14)
            let IsHeadingColumn = Int(sqlite3_column_int(QueryHandle, 15))
            let HeadingTimeColumn = String(cString: sqlite3_column_text(QueryHandle, 16))
            
            var SomeLocation: DataPoint? = nil
            let HeadingChanged = !(IsHeadingColumn == 0)
            if HeadingChanged
            {
                SomeLocation = DataPoint(WithNewHeading: HeadingColumn, TimeStamp: Utilities.StringToDate(HeadingTimeColumn)!)
            }
            else
            {
                let Coordinate = CLLocationCoordinate2D(latitude: Double(LatitudeColumn)!,
                                                        longitude: Double(LongitudeColumn)!)
                let Altitude = Double(AltitudeColumn)!
                let HAccuracy = Double(HorizontalAccuracyColumn)!
                let VAccuracy = Double(VerticalAccuracyColumn)!
                let Course = Double(CourseColumn)!
                let Speed = Double(SpeedColumn)!
                let DataLocation = CLLocation(coordinate: Coordinate,
                                              altitude: Altitude,
                                              horizontalAccuracy: HAccuracy,
                                              verticalAccuracy: VAccuracy,
                                              course: Course,
                                              speed: Speed,
                                              timestamp: Utilities.StringToDate(TimeStampColumn)!)
                let Marked = Bool(MarkedColumn)!
                SomeLocation = DataPoint(WithLocation: DataLocation, IsMarked: Marked, Delegate: nil, SkipAddress: true)
                SomeLocation?.DecodedAddress = AddressColumn
                SomeLocation?.InstanceCount = InstanceColumn
            }
            SomeLocation?.EntryID = UUID(uuidString: EntryIDColumn)!
            SomeLocation?.SessionID = UUID(uuidString: SessionColumn)!
            Results.append(SomeLocation!)
        }
        return Results
    }
    
    /// Returns a list of all sessions in the **Sessions** table in the database.
    /// - Parameter DB: The database handle.
    /// - Parameter ForID: If specified, only the session with this value will be returned in the array. If nil (default value),
    ///                    all sessions will be returned.
    /// - Parameter UseTestData: If true, data from the test tables will be used.
    /// - Returns: Array of session data. Empty array on error.
    public static func SessionList(DB: OpaquePointer?, ForID: UUID? = nil, UseTestData: Bool = false) -> [SessionData]
    {
        if DB == nil
        {
            return []
        }
        var Results: [SessionData] = [SessionData]()
        let TableName = UseTestData ? "TestSessions" : "Sessions"
        let GetSQL = "SELECT * FROM \(TableName)"
        let QueryHandle = SetupQuery(DB: DB, Query: GetSQL)
        while (sqlite3_step(QueryHandle) == SQLITE_ROW)
        {
            let SessionIDColumn = String(cString: sqlite3_column_text(QueryHandle, 1))
            if ForID != nil
            {
                let WorkingID = UUID(uuidString: SessionIDColumn)!
                if WorkingID != ForID!
                {
                    continue
                }
            }
            let StartColumn = String(cString: sqlite3_column_text(QueryHandle, 2))
            let EndColumn = String(cString: sqlite3_column_text(QueryHandle, 3))
            let NameColumn = String(cString: sqlite3_column_text(QueryHandle, 4))
            let SData = SessionData(Name: NameColumn, ID: UUID(uuidString: SessionIDColumn)!,
                                    Start: Utilities.StringToDate(StartColumn)!, End: Utilities.StringToDate(EndColumn))
            Results.append(SData)
        }
        return Results
    }
    
    /// Returns the number of entries if the table pointed to by `DB`.
    /// - Note: See [How to get row count from table](https://stackoverflow.com/questions/53479057/swift-sqlite-how-to-get-row-count-from-table)
    /// - Note: If `DB` is nil, a fatal error will be generated.
    /// - Parameter DB: The handle of the database where the table lives whose count will be returned.
    /// - Parameter TableName: The name of the table whose count will be returned.
    /// - Returns: Number of entries in the specified table on success, nil on error.
    private static func GetTableCount(DB: OpaquePointer?, TableName: String) -> Int?
    {
        if DB == nil
        {
            fatalError("Database handle nil in GetTableCount")
        }
        let GetCount = "SELECT COUNT(*) FROM \(TableName)"
        var CountQuery: OpaquePointer? = nil
        if sqlite3_prepare(DB, GetCount, -1, &CountQuery, nil) == SQLITE_OK
        {
            while sqlite3_step(CountQuery) == SQLITE_ROW
            {
                let Count = sqlite3_column_int(CountQuery, 0)
                return Int(Count)
            }
        }
        return nil
    }
    
    /// Returns the number of entries in the session table.
    /// - Note: If `DB` is nil, a fatal error will be generated.
    /// - Parameter DB: The handle of the database where the sessions table lives.
    /// - Parameter UseTestData: If true use test data.
    /// - Returns: The number of rows in the session table on success, nil on error.
    public static func GetSessionCount(DB: OpaquePointer?, UseTestData: Bool = false) -> Int?
    {
        let TableName = UseTestData ? "TestSessions" : "Sessions"
    return GetTableCount(DB: DB, TableName: TableName)
    }
    
    /// Returns the number of entries in the entries table.
    /// - Note: If `DB` is nil, a fatal error will be generated.
    /// - Parameter DB: The handle of the database where the entries table lives.
    /// - Parameter UseTestData: If true use test data.
    /// - Returns: The number of rows in the entries table on success, nil on error.
    public static func GetEntryCount(DB: OpaquePointer?, UseTestData: Bool = false) -> Int?
    {
        let TableName = UseTestData ? "TestEntries" : "Entries"
        return GetTableCount(DB: DB, TableName: TableName)
    }
    
    /// Returns the number of entries for the passed session ID.
    /// - Note: See [Sqlite Count Function](https://www.sqlitetutorial.net/sqlite-count-function/)
    /// - Note: If `DB` is nil, a fatal error will be generated.
    /// - Parameter DB: The handle of the database where the entries table lives.
    /// - Parameter SessionID: The ID of the session whose entry count will be returned.
    /// - Parameter UseTestData: If true, use test data.
    /// - Returns: The number of entries whose session ID is `SessionID`. Nil on error.
    public static func EntryCountForSession(DB: OpaquePointer?, SessionID: UUID, UseTestData: Bool = false) -> Int?
    {
        if DB == nil
        {
            fatalError("Database handle nil in EntryCountForSession")
        }
        let TableName = UseTestData ? "TestEntries" : "Entries"
        let ID = SessionID.uuidString
        let GetCount = "SELECT COUNT(*) FROM \(TableName) WHERE Session = '\(ID)';"
        var CountQuery: OpaquePointer? = nil
        if sqlite3_prepare(DB, GetCount, -1, &CountQuery, nil) == SQLITE_OK
        {
            while sqlite3_step(CountQuery) == SQLITE_ROW
            {
                let Count = sqlite3_column_int(CountQuery, 0)
                return Int(Count)
            }
        }
        return nil
    }
    
    /// Retreives a session and its associated data from the database.
    /// - Note: If `DB` is nil, a fatal error is generated.
    /// - Parameter DB: The database handle.
    /// - Parameter SessionID: The ID of the session that will be returned.
    /// - Parameter UseTestData: If true, use the test entry table.
    /// - Returns: Returns a fully populated session on success, nil on error.
    public static func RetreiveSession(DB: OpaquePointer?, SessionID: UUID, UseTestData: Bool = false) -> SessionData?
    {
        if DB == nil
        {
            fatalError("Database handle nil in RetreiveSession")
        }
        let Sessions = SessionList(DB: DB, ForID: SessionID, UseTestData: UseTestData)
        if Sessions.count != 1
        {
            return nil
        }
        let Session = Sessions[0]
        Session.Locations = GetSessionData(DB: DB, SessionID: SessionID, UseTestData: UseTestData)
        return Session
    }
    
    public static var LastSQLErrorCode: Int32 = SQLITE_OK
    public static var LastSQLErrorMessage: String = ""
}
