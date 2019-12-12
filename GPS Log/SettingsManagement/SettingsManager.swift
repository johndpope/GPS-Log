//
//  SettingsManager.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/11/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Wrapper around `UserDefaults.standard` to provide atomic-level change notification for settings.
/// - Note:
///   - See the enum `SettingKeys` for a description of each setting.
///   - Currently, settings are stored in `UserDefaults.standard`. However, it is straightforward to refactor this class to use
///     a different storage type, such as a database or .XML or .JSON file.
/// - Warning: If the caller tries to access a setting with the incorrect type (such as calling `GetBoolean` with a String-
///            backed setting), a fatal error will be generated. See `GetSettingType` for a way to avoid this.
class Settings
{
    /// Table of subscribers.
    private static var Subscribers = [(String, SettingChangedProtocol?)]()
    
    /// Initialize the class. Creates the default set of settings if they do not exist.
    public static func Initialize ()
    {
        InitializeDefaults()
    }
    
    /// Add a subscriber to the notification list. Each subscriber is called just before a setting is committed and just after
    /// it is committed.
    /// - Parameter NewSubscriber: The delegate of the new subscriber.
    /// - Parameter Owner: The name of the owner.
    public static func AddSubscriber(_ NewSubscriber: SettingChangedProtocol, _ Owner: String)
    {
        Subscribers.append((Owner, NewSubscriber))
    }
    
    /// Remove a subscriber from the notification list.
    /// - Parameter Name: The name of the subscriber to remove. Must be identical to the name supplied to `AddSubscriber`.
    public static func RemoveSubscriber(_ Name: String)
    {
        Subscribers = Subscribers.filter{$0.0 != Name}
    }
    
    /// Initialize defaults if there are no current default settings available.
    public static func InitializeDefaults()
    {
        if UserDefaults.standard.string(forKey: "Initialized") == nil
        {
            AddDefaultSettings()
        }
    }
    
    /// Create and add default settings.
    /// - Note: If called after initialize instantiation, all user-settings will be overwritten. User data
    ///         (in the form of the log database) will *not* be affected.
    public static func AddDefaultSettings()
    {
        UserDefaults.standard.set("Initialized", forKey: "Initialized")
        UserDefaults.standard.set(1, forKey: SettingKeys.Period.rawValue)
        UserDefaults.standard.set("Table", forKey: SettingKeys.DataViews.rawValue)
        UserDefaults.standard.set(true, forKey: SettingKeys.DiscardDuplicates.rawValue)
        UserDefaults.standard.set(10.0, forKey: SettingKeys.HorizontalCloseness.rawValue)
        UserDefaults.standard.set(10.0, forKey: SettingKeys.VerticalCloseness.rawValue)
        UserDefaults.standard.set(true, forKey: SettingKeys.CollectDataInBackground.rawValue)
        UserDefaults.standard.set(true, forKey: SettingKeys.DecodeAddresses.rawValue)
        UserDefaults.standard.set(true, forKey: SettingKeys.StayAwake.rawValue)
        UserDefaults.standard.set(true, forKey: SettingKeys.TrackHeadings.rawValue)
        UserDefaults.standard.set(10.0, forKey: SettingKeys.HeadingSensitivity.rawValue)
        UserDefaults.standard.set("Standard", forKey: SettingKeys.MapType.rawValue)
        UserDefaults.standard.set(true, forKey: SettingKeys.ShowCurrentLocation.rawValue)
        UserDefaults.standard.set(true, forKey: SettingKeys.ShowCompass.rawValue)
        UserDefaults.standard.set(true, forKey: SettingKeys.ShowBuildings.rawValue)
        UserDefaults.standard.set(false, forKey: SettingKeys.ShowTraffic.rawValue)
        UserDefaults.standard.set(true, forKey: SettingKeys.ShowScale.rawValue)
        UserDefaults.standard.set(true, forKey: SettingKeys.ShowBadge.rawValue)
        UserDefaults.standard.set(true, forKey: SettingKeys.ShowMapBusyIndicator.rawValue)
        UserDefaults.standard.set(45.0, forKey: SettingKeys.MapPitch.rawValue)
        UserDefaults.standard.set(true, forKey: SettingKeys.MapInPerspective.rawValue)
        UserDefaults.standard.set("", forKey: SettingKeys.LastLongitude.rawValue)
        UserDefaults.standard.set("", forKey: SettingKeys.LastLatitude.rawValue)
        UserDefaults.standard.set("", forKey: SettingKeys.LastAltitude.rawValue)
        UserDefaults.standard.set(true, forKey: SettingKeys.ShowHemisphereLabels.rawValue)
    }
    
    /// Call all subscribers in the notification list to let them know a setting will be changed.
    /// - Note: Callers have the opportunity to cancel the request. If the caller sets `CancelChange` in the protocol to
    ///         false, they want to cancel the settings change. If there are multiple subscribers and different responses,
    ///         the last response will take precedence.
    /// - Parameter WithKey: The key of the setting that will be changed.
    /// - Parameter AndValue: The new value (cast to Any).
    /// - Parameter CancelRequested: Will contain the caller's cancel change request on return.
    private static func NotifyWillChange(WithKey: SettingKeys, AndValue: Any, CancelRequested: inout Bool)
    {
        var RequestCancel = false
        Subscribers.forEach{$0.1?.WillChangeSetting(WithKey, NewValue: AndValue, CancelChange: &RequestCancel)}
        CancelRequested = RequestCancel
    }
    
    /// Send a notification to all subscribers that a settings change occurred.
    /// - Parameter WithKey: The key that changed.
    private static func NotifyDidChange(WithKey: SettingKeys)
    {
        Subscribers.forEach{$0.1?.DidChangeSetting(WithKey)}
    }
    
    /// Saves a boolean value to the settings.
    /// - Note: If `ForKey` is not a boolean setting, a fatal error will be generated.
    /// - Parameter NewValue: The boolean value to set.
    /// - Parameter ForKey: The key to set.
    public static func SetBoolean(_ NewValue: Bool, ForKey: SettingKeys)
    {
        if BooleanFields.contains(ForKey)
        {
            var Cancel = false
            NotifyWillChange(WithKey: ForKey, AndValue: NewValue as Any, CancelRequested: &Cancel)
            if Cancel
            {
                return
            }
            UserDefaults.standard.set(NewValue, forKey: ForKey.rawValue)
            NotifyDidChange(WithKey: ForKey)
        }
        else
        {
            fatalError("The key \(ForKey.rawValue) does not point to a boolean setting.")
        }
    }
    
    /// Saves a boolean value to the settings.
    /// - Note: If `ForKey` is not a boolean setting, a fatal error will be generated.
    /// - Parameter NewValue: The boolean value to set.
    /// - Parameter ForKey: The key to set.
    /// - Parameter Completed: Completion handler.
    public static func SetBoolean(_ NewValue: Bool, ForKey: SettingKeys, Completed: ((SettingKeys) -> Void))
    {
        if BooleanFields.contains(ForKey)
        {
            var Cancel = false
            NotifyWillChange(WithKey: ForKey, AndValue: NewValue as Any, CancelRequested: &Cancel)
            if Cancel
            {
                return
            }
            UserDefaults.standard.set(NewValue, forKey: ForKey.rawValue)
            NotifyDidChange(WithKey: ForKey)
        }
        else
        {
            fatalError("The key \(ForKey.rawValue) does not point to a boolean setting.")
        }
        Completed(ForKey)
    }
    
    /// Returns the value of a boolean setting.
    /// - Note: If `ForKey` is not a boolean setting, a fatal error will be generated.
    /// - Parameter ForKey: The setting whose value will be returned.
    public static func GetBoolean(ForKey: SettingKeys) -> Bool
    {
        if BooleanFields.contains(ForKey)
        {
            return UserDefaults.standard.bool(forKey: ForKey.rawValue)
        }
        else
        {
            fatalError("The key \(ForKey.rawValue) does not point to a boolean setting.")
        }
    }
    
    /// Saves a Double value to the settings.
    /// - Note: If `ForKey` is not a Double setting, a fatal error will be generated.
    /// - Parameter NewValue: The Double value to set.
    /// - Parameter ForKey: The key to set.
    public static func SetDouble(_ NewValue: Double, ForKey: SettingKeys)
    {
        if DoubleFields.contains(ForKey)
        {
            var Cancel = false
            NotifyWillChange(WithKey: ForKey, AndValue: NewValue as Any, CancelRequested: &Cancel)
            if Cancel
            {
                return
            }
            UserDefaults.standard.set(NewValue, forKey: ForKey.rawValue)
            NotifyDidChange(WithKey: ForKey)
        }
        else
        {
            fatalError("The key \(ForKey.rawValue) does not point to a double setting.")
        }
    }
    
    /// Saves a Double value to the settings.
    /// - Note: If `ForKey` is not a Double setting, a fatal error will be generated.
    /// - Parameter NewValue: The Double value to set.
    /// - Parameter ForKey: The key to set.
    /// - Parameter Completed: Completion handler.
    public static func SetDouble(_ NewValue: Double, ForKey: SettingKeys, Completed: ((SettingKeys) -> Void))
    {
        if DoubleFields.contains(ForKey)
        {
            var Cancel = false
            NotifyWillChange(WithKey: ForKey, AndValue: NewValue as Any, CancelRequested: &Cancel)
            if Cancel
            {
                return
            }
            UserDefaults.standard.set(NewValue, forKey: ForKey.rawValue)
            NotifyDidChange(WithKey: ForKey)
        }
        else
        {
            fatalError("The key \(ForKey.rawValue) does not point to a double setting.")
        }
        Completed(ForKey)
    }
    
    /// Returns the value of a Double setting.
    /// - Note: If `ForKey` is not a Double setting, a fatal error will be generated.
    /// - Parameter ForKey: The setting whose value will be returned.
    public static func GetDouble(ForKey: SettingKeys) -> Double
    {
        if DoubleFields.contains(ForKey)
        {
            return UserDefaults.standard.double(forKey: ForKey.rawValue)
        }
        else
        {
            fatalError("The key \(ForKey.rawValue) does not point to a double setting.")
        }
    }
    
    /// Saves an integer value to the settings.
    /// - Note: If `ForKey` is not an integer setting, a fatal error will be generated.
    /// - Parameter NewValue: The integer value to set.
    /// - Parameter ForKey: The key to set.
    public static func SetInteger(_ NewValue: Int, ForKey: SettingKeys)
    {
        if IntegerFields.contains(ForKey)
        {
            var Cancel = false
            NotifyWillChange(WithKey: ForKey, AndValue: NewValue as Any, CancelRequested: &Cancel)
            if Cancel
            {
                return
            }
            UserDefaults.standard.set(NewValue, forKey: ForKey.rawValue)
            NotifyDidChange(WithKey: ForKey)
        }
        else
        {
            fatalError("The key \(ForKey.rawValue) does not point to an integer setting.")
        }
    }
    
    /// Saves an integer value to the settings.
    /// - Note: If `ForKey` is not an integer setting, a fatal error will be generated.
    /// - Parameter NewValue: The integer value to set.
    /// - Parameter ForKey: The key to set.
    /// - Completed: Completion handler.
    public static func SetInteger(_ NewValue: Int, ForKey: SettingKeys, Completed: ((SettingKeys) -> Void))
    {
        if IntegerFields.contains(ForKey)
        {
            var Cancel = false
            NotifyWillChange(WithKey: ForKey, AndValue: NewValue as Any, CancelRequested: &Cancel)
            if Cancel
            {
                return
            }
            UserDefaults.standard.set(NewValue, forKey: ForKey.rawValue)
            NotifyDidChange(WithKey: ForKey)
        }
        else
        {
            fatalError("The key \(ForKey.rawValue) does not point to an integer setting.")
        }
        Completed(ForKey)
    }
    
    /// Returns the value of an integer setting.
    /// - Note: If `ForKey` is not an integer setting, a fatal error will be generated.
    /// - Parameter ForKey: The setting whose value will be returned.
    public static func GetInteger(ForKey: SettingKeys) -> Int
    {
        if IntegerFields.contains(ForKey)
        {
            return UserDefaults.standard.integer(forKey: ForKey.rawValue)
        }
        else
        {
            fatalError("The key \(ForKey.rawValue) does not point to an integer setting.")
        }
    }
    
    /// Saves a string value to the settings.
    /// - Note: If `ForKey` is not a string setting, a fatal error will be generated.
    /// - Parameter NewValue: The string value to set.
    /// - Parameter ForKey: The key to set.
    public static func SetString(_ NewValue: String, ForKey: SettingKeys)
    {
        if StringFields.contains(ForKey)
        {
            var Cancel = false
            NotifyWillChange(WithKey: ForKey, AndValue: NewValue as Any, CancelRequested: &Cancel)
            if Cancel
            {
                return
            }
            UserDefaults.standard.set(NewValue, forKey: ForKey.rawValue)
            NotifyDidChange(WithKey: ForKey)
        }
        else
        {
            fatalError("The key \(ForKey.rawValue) does not point to a string setting.")
        }
    }
    
    /// Saves a string value to the settings.
    /// - Note: If `ForKey` is not a string setting, a fatal error will be generated.
    /// - Parameter NewValue: The string value to set.
    /// - Parameter ForKey: The key to set.
    /// - Parameter Completed: Completion handler.
    public static func SetString(_ NewValue: String, ForKey: SettingKeys, Completed: ((SettingKeys) -> Void))
    {
        if StringFields.contains(ForKey)
        {
            var Cancel = false
            NotifyWillChange(WithKey: ForKey, AndValue: NewValue as Any, CancelRequested: &Cancel)
            if Cancel
            {
                return
            }
            UserDefaults.standard.set(NewValue, forKey: ForKey.rawValue)
            NotifyDidChange(WithKey: ForKey)
        }
        else
        {
            fatalError("The key \(ForKey.rawValue) does not point to a string setting.")
        }
        Completed(ForKey)
    }
    
    /// Returns the value of a string setting.
    /// - Note: If `ForKey` is not a string setting, a fatal error will be generated.
    /// - Parameter ForKey: The setting whose value will be returned. Nil will be returned if the contents of
    ///                     `ForKey` are not set.
    public static func GetString(ForKey: SettingKeys) -> String?
    {
        if StringFields.contains(ForKey)
        {
            return UserDefaults.standard.string(forKey: ForKey.rawValue)
        }
        else
        {
            fatalError("The key \(ForKey.rawValue) does not point to a string setting.")
        }
    }
    
    /// Returns the type of the backing data for the passed setting.
    /// - Parameter ForSetting: The setting whose backing type will be returned.
    /// - Returns: Backing type for the setting. `.Unknown` is returned if the type system does not yet comprehend the passed setting.
    public static func GetSettingType(_ ForSetting: SettingKeys) -> SettingTypes
    {
        if BooleanFields.contains(ForSetting)
        {
            return .Boolean
        }
        if IntegerFields.contains(ForSetting)
        {
            return .Integer
        }
        if DoubleFields.contains(ForSetting)
        {
            return .Double
        }
        if StringFields.contains(ForSetting)
        {
            return .String
        }
        return .Unknown
    }
    
    /// Contains a list of all boolean-type fields.
    public static let BooleanFields =
        [
            SettingKeys.DiscardDuplicates,
            SettingKeys.CollectDataInBackground,
            SettingKeys.DecodeAddresses,
            SettingKeys.StayAwake,
            SettingKeys.TrackHeadings,
            SettingKeys.ShowCurrentLocation,
            SettingKeys.ShowCompass,
            SettingKeys.ShowBuildings,
            SettingKeys.ShowTraffic,
            SettingKeys.ShowScale,
            SettingKeys.ShowBadge,
            SettingKeys.ShowMapBusyIndicator,
            SettingKeys.MapInPerspective,
            SettingKeys.ShowHemisphereLabels
    ]
    
    /// Contains a list of all integer-type fields.
    public static let IntegerFields =
        [
            SettingKeys.Period
    ]
    
    /// Contains a list of all string-type fields.
    public static let StringFields =
        [
            SettingKeys.MapType,
            SettingKeys.DataViews,
            SettingKeys.LastLongitude,
            SettingKeys.LastLatitude,
            SettingKeys.LastAltitude
    ]
    
    /// Contains a list of all double-type fields.
    public static let DoubleFields =
        [
            SettingKeys.HorizontalCloseness,
            SettingKeys.VerticalCloseness,
            SettingKeys.HeadingSensitivity,
            SettingKeys.MapPitch
    ]
}

/// Keys for user settings.
enum SettingKeys: String, CaseIterable
{
    //Booleans
    /// Holds the discard duplication locations flag. Duplicates are defined as one or more received locations that fall within
    /// the user-defined volume of the last non-duplicate location. Marked locations are not bound by this flag.
    case DiscardDuplicates = "DiscardDuplicates"
    /// Holds the collect data in the background flag. May drain the user's battery quickly.
    case CollectDataInBackground = "CollectDataWhenInBackground"
    /// Holds the decode address of coordinate flag. Apple's API is throttled so it is very possible addresses will not be available
    /// for all locations.
    case DecodeAddresses = "DecodeAddresses"
    /// Holds the stay awake flag, which means the app does not go to sleep to reduce power usaged. May impact battery power levels.
    case StayAwake = "StayAwake"
    /// Holds the track heading changes flag. Set the `HeadingSensitivity` value appropriately or the user will receive a great many
    /// heading changes just by holding the phone.
    case TrackHeadings = "TrackHeadings"
    /// Holds the show user's current location on the map flag.
    case ShowCurrentLocation = "ShowCurrentLocation"
    /// Holds the show compass on the map flag.
    case ShowCompass = "ShowCompass"
    /// Holds the show buildings (which will be extruded if `MapInPerspective` is true) on the map flag.
    case ShowBuildings = "ShowBuildings"
    /// Holds the show traffic on the map flag. Uses network to receive traffic information, which will increase data usage and
    /// battery usage.
    case ShowTraffic = "ShowTraffic"
    /// Holds the show map scale flag.
    case ShowScale = "ShowScale"
    /// Holds the show accumulated points in a session on the app icon flag.
    case ShowBadge = "ShowAccumulatedPointsAsBadge"
    /// Holds the show map tiles downloading busy indicator.
    case ShowMapBusyIndicator = "ShowMapBusyIndicator"
    /// Holds the map is in perspective mode flag. Use `MapPitch` to set the pitch angle of the map.
    case MapInPerspective = "MapInPerspective"
    /// Holds the show hemispheric labels (eg, N, S, E, W) on coordinates flag.
    case ShowHemisphereLabels = "ShowHemisphereLabels"
    //Integers
    /// Holds the period between collecting locations. Unit is seconds.
    case Period = "Period"
    //Strings
    /// Holds the type of map. Generated from the `MapTypes` enum.
    case MapType = "MapType"
    /// Holds the type of data view. Generated from the `DataViews` enum.
    case DataViews = "DataViews"
    /// Holds the most recent longitude.
    case LastLongitude = "LastLongitude"
    /// Holds the most recent latitude.
    case LastLatitude = "LastLatitude"
    /// Holds the most recent altitude.
    case LastAltitude = "LastAltitude"
    //Doubles
    /// Horizontal radius for determining if a given location is a duplicate of the previously saved point.
    case HorizontalCloseness = "HorizontalCloseness"
    /// Vertical radius for determining if a given location is a duplicate of the previously saved point.
    case VerticalCloseness = "VerticalCloseness"
    /// Determines how many degress the device must rotate to trigger a heading changed event.
    case HeadingSensitivity = "HeadingSensitivity"
    /// The pitch of the map when in perspective mode.
    case MapPitch = "MapPitch"
}

/// Types of setting data recognized by the SettingsManager.
enum SettingTypes: String, CaseIterable
{
    /// Returned when the caller finds a setting that is not yet integrated into the type system.
    case Unknown = "Unknown Type"
    /// `Bool` types.
    case Boolean = "Boolean"
    /// `String` types.
    case String = "String"
    /// `Int` types.
    case Integer = "Integer"
    /// `Double` types.
    case Double = "Double"
}
