//
//  ViewController.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import SQLite3
import MapKit
import OfficeUIFabric

class ViewController: UIViewController,
    UITableViewDelegate,
    UITableViewDataSource,
    CLLocationManagerDelegate,
    MKMapViewDelegate,
    DataPointUpdatedProtocol,
    MainProtocol,
    SettingChangedProtocol
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        UpdateBadgeCount(0)
        //Create a dummy session to keep the UI happy.
        CurrentSession = SessionData()
        InitializeMapViewer()
        InitializeBusyIndicator()
        InitializeLocationManager()
        DataPointTable.layer.borderColor = UIColor.black.cgColor
        DBManager.VerifyDatabase("Log.db")
        DBHandle = DBManager.GetDatabaseHandle("Log.db")
        Settings.AddSubscriber(self, "Main")
        CurrentView = DataViews(rawValue: Settings.GetString(ForKey: .DataViews)!)!
        switch CurrentView
        {
            case .Table:
                HandleTableSelected()
            
            case .AppleMap:
                HandleMapSelected()
            
            default:
                HandleTableSelected()
        }
    }
    
    var DBHandle: OpaquePointer? = nil
    
    /// Set the map's camera position and pitch.
    func SetMapCamera(CenteredOn: CLLocationCoordinate2D, AtAltitude: Double)
    {
        let OldCamera = MapViewer.camera
        let MapCamera = MKMapCamera()
        MapCamera.centerCoordinate = CenteredOn
        if Settings.GetBoolean(ForKey: .MapInPerspective)
        {
            let MapPitch = Settings.GetDouble(ForKey: .MapPitch)
            print("Setting map pitch to \(MapPitch)")
            MapViewer.isPitchEnabled = true
            MapCamera.pitch = CGFloat(MapPitch)
        }
        else
        {
            print("Disabling pitch.")
            MapViewer.isPitchEnabled = false
        }
        MapCamera.altitude = AtAltitude
        MapCamera.heading = 0.0
        if MapCamera.altitude == OldCamera.altitude &&
            MapCamera.heading == OldCamera.heading &&
            MapCamera.pitch == OldCamera.pitch
        {
            return
        }
        MapViewer.camera = MapCamera
    }
    
    /// Initialize the location manager.
    func InitializeLocationManager()
    {
        LocationManager = CLLocationManager()
        LocationManager?.delegate = self
        LocationManager?.requestAlwaysAuthorization()
        LocationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        LocationManager?.allowsBackgroundLocationUpdates = true
        LocationManager?.headingFilter = Settings.GetDouble(ForKey: .HeadingSensitivity)
        LocationManager?.startUpdatingLocation()
        LocationManager?.startUpdatingHeading()
    }
    
    func WillChangeSetting(_ ChangedSetting: SettingKeys, NewValue: Any, CancelChange: inout Bool)
    {
        CancelChange = false
    }
    
    func DidChangeSetting(_ ChangedSetting: SettingKeys)
    {
        switch ChangedSetting
        {
            case .ShowMapBusyIndicator:
                if !Settings.GetBoolean(ForKey: .ShowMapBusyIndicator)
                {
                    HideBusyIndicator()
            }
            
            case .MapInPerspective:
                if Settings.GetBoolean(ForKey: .MapInPerspective)
                {
                    MapViewer.isPitchEnabled = false
                    if let MostRecentLocation = GetMostRecentLocationInSession()
                    {
                        SetMapCamera(CenteredOn: MostRecentLocation.Location!.coordinate, AtAltitude: 500.0)
                    }
                    else
                    {
                        GetInitialPositionForMap = true
                    }
                }
                else
                {
                    MapViewer.isPitchEnabled = false
            }
            
            case .ShowScale:
                MapViewer.showsScale = Settings.GetBoolean(ForKey: .ShowScale)
            
            case .ShowCompass:
                MapViewer.showsCompass = Settings.GetBoolean(ForKey: .ShowCompass)
            
            case .ShowTraffic:
                MapViewer.showsTraffic = Settings.GetBoolean(ForKey: .ShowTraffic)
            
            case .ShowBuildings:
                MapViewer.showsBuildings = Settings.GetBoolean(ForKey: .ShowBuildings)
            
            case .ShowCurrentLocation:
                MapViewer.showsUserLocation = Settings.GetBoolean(ForKey: .ShowCurrentLocation)
            
            case .MapType:
                var MapType = MKMapType.standard
                if let RawMapType = Settings.GetString(ForKey: .MapType)
                {
                    let TheMapType = MapTypes(rawValue: RawMapType)!
                    switch TheMapType
                    {
                        case .Standard:
                            MapType = .standard
                        
                        case .MutedStandard:
                            MapType = .mutedStandard
                        
                        case .Hybrid:
                            MapType = .hybrid
                        
                        case .Satellite:
                            MapType = .satellite
                        
                        case .HybridFlyover:
                            MapType = .hybridFlyover
                        
                        case .SatelliteFlyover:
                            MapType = .satelliteFlyover
                    }
                }
                else
                {
                    Settings.SetString(MapTypes.Standard.rawValue, ForKey: .MapType)
                }
                MapViewer.mapType = MapType
            
            case .HeadingSensitivity:
                LocationManager?.headingFilter = Settings.GetDouble(ForKey: .HeadingSensitivity)
            
            case .TrackHeadings:
                if Settings.GetBoolean(ForKey: .TrackHeadings)
                {
                    LocationManager?.startUpdatingHeading()
                }
                else
                {
                    LocationManager?.stopUpdatingHeading()
            }
            
            case .DataViews:
                let ViewValue = Settings.GetString(ForKey: .DataViews)
                if let NewViewValue = DataViews(rawValue: ViewValue!)
                {
                    if NewViewValue != CurrentView
                    {
                        switch NewViewValue
                        {
                            case .Table:
                                HandleTableSelected()
                            
                            case .AppleMap:
                                HandleMapSelected()
                            
                            default:
                                break
                        }
                    }
            }
            
            default:
                #if DEBUG
                print("Change to \(ChangedSetting.rawValue) unhandled.")
                #endif
                break
        }
    }
    
    /// Returns the current database handle.
    func Handle() -> OpaquePointer?
    {
        return DBHandle
    }
    
    var LocationManager: CLLocationManager? = nil
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if CurrentSession == nil
        {
            return 0
        }
        return CurrentSession!.Locations.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return LocationCell.CellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if CurrentSession == nil
        {
            return UITableViewCell()
        }
        let Cell = LocationCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "LocationCell")
        Cell.LoadData(LocationData: CurrentSession!.Locations[indexPath.row], TableWidth: DataPointTable.frame.width,
                      MainFontSize: 16.0)
        return Cell
    }
    
    /// Run a dialog/alert to ask the user whether to save the session's data or discard it. If the user cancels,
    /// the data will not be deleted but the user must remember to save it later.
    /// - Note: Saving and discarding are each handled in their separate closures.
    func RunSaveSessionDialog()
    {
        let Alert = UIAlertController(title: "Save Session", message: "Please enter the name of your session.",
                                      preferredStyle: UIAlertController.Style.alert)
        Alert.addTextField
            {
                Field in
                Field.clearButtonMode = .always
                if self.CurrentSession!.Name.isEmpty
                {
                    Field.text = Utilities.DateToString(self.CurrentSession!.SessionStart)
                }
                else
                {
                    Field.text = self.CurrentSession!.Name
                }
        }
        Alert.addAction(UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler:
            {
                _ in
                var SessionName = Alert.textFields![0].text
                if SessionName!.isEmpty
                {
                    SessionName = Utilities.DateToString(self.CurrentSession!.SessionStart)
                }
                self.CurrentSession!.Name = SessionName!
                self.SaveCurrentSession()
        }))
        self.present(Alert, animated: true, completion: nil)
    }
    
    /// Save the current session to the database.
    func SaveCurrentSession()
    {
        if CurrentSession == nil
        {
            print("Cannot save session - CurrentSession is nil.")
            return
        }
        DBManager.WriteSession(DB: DBHandle, SessionID: CurrentSession!.ID, StartTime: CurrentSession!.SessionStart,
                               EndTime: CurrentSession!.SessionEnd, SessionName: CurrentSession!.Name)
        CurrentSession!.Saved = true
    }
    
    /// Discard the current session. Remove the data from the view.
    /// - Parameter Action: Not used.
    func DiscardCurrentSession(_ Action: UIAlertAction)
    {
        CurrentSession = SessionData()
        DataPointTable.reloadData()
        RemoveAllAnnotations()
    }
    
    /// Handle the start button pressed. Depending on the current running state, the start button may in reality
    /// be the stop button. When the stop button is pressed, the user is asked whether to save the data or not.
    /// This is done in `RunSaveSessionDialog` and the saving (or discarding) is handled asynchronously.
    /// - Parameter sender: Not used.
    @IBAction func HandleStartPressed(_ sender: Any)
    {
        if Running
        {
            LocationManager?.stopUpdatingLocation()
            LocationManager?.stopUpdatingHeading()
            CurrentSession?.SessionEnd = Date()
            RunSaveSessionDialog()
            StartButton.setImage(UIImage(systemName: "play.fill"), for: UIControl.State.normal)
            StartButton.tintColor = UIColor.systemGreen
        }
        else
        {
            LocationManager?.startUpdatingLocation()
            LocationManager?.startUpdatingHeading()
            UpdateBadgeCount(0)
            CurrentSessionID = UUID()
            CurrentSession = SessionData()
            CurrentSession?.ID = CurrentSessionID
            CurrentSession?.SessionStart = Date()
            StartButton.setImage(UIImage(systemName: "stop.fill"), for: UIControl.State.normal)
            StartButton.tintColor = UIColor.systemRed
            DataPointTable.reloadData()
            RemoveAllAnnotations()
            StartedRunning = CACurrentMediaTime()
        }
        Running = !Running
    }
    
    var CurrentSession: SessionData?
    var SessionName: String = ""
    var CurrentSessionID: UUID = UUID()
    
    var StartedRunning: Double = 0
    
    /// Add a new data point. The data point is added to the current session's list of data points. Both the
    /// data table and map views are updated (even though only one is visible at a time - this allows for faster
    /// switching by the user). If allowed, the number of "active" (eg, data points in the current session) are
    /// shown on the app's icon as a badge.
    /// - Parameter Location: The data point to add.
    func AddNewDataPoint(_ Location: DataPoint)
    {
        if CurrentSession == nil
        {
            return
        }
        OperationQueue.main.addOperation
            {
                self.CurrentSession!.Locations.insert(Location, at: 0)
                self.UpdateMapWith(Location)
                self.DataPointTable.reloadData()
                if Settings.GetBoolean(ForKey: .ShowBadge)
                {
                    let Count = self.CurrentSession!.Locations.count
                    if Count > 0
                    {
                        self.UpdateBadgeCount(Count)
                    }
                }
        }
    }
    
    /// Update the badge count on the app's icon. The value is assumed to be the number of active data points
    /// in the current session.
    func UpdateBadgeCount(_ NewCount: Int = 0)
    {
        let App = UIApplication.shared
        let UNNot = UNUserNotificationCenter.current()
        UNNot.requestAuthorization(options: [.badge])
        {
            (granted, error) in
            if granted
            {
                OperationQueue.main.addOperation
                    {
                        App.registerForRemoteNotifications()
                        App.applicationIconBadgeNumber = NewCount
                }
            }
            else
            {
                print("Not authorized to display badge information.")
            }
        }
    }
    
    @objc func TimeToGetLocation()
    {
        LocationManager?.requestLocation()
    }
    
    var Running = false
    
    var PeriodTimer: Timer!
    
    var SaveMarkedLocation: Bool = false
    
    @IBAction func HandleMarkLocationPressed(_ sender: Any)
    {
        SaveMarkedLocation = true
        LocationManager?.requestLocation()
    }
    
    // MARK: Location manager delegates.
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        let ErrorMessage = "Location manager error: \(error.localizedDescription)"
        let AlertView = UIAlertController(title: "Location Error", message: ErrorMessage, preferredStyle: UIAlertController.Style.alert)
        AlertView.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
        self.present(AlertView, animated: true)
    }
    
    /// New locations are available from the location manager.
    /// - Parameter manager: Not used.
    /// - Parameter didUpdateLocaionts: Array of new locations. We only care about the last one (and usually there is only one).
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        Settings.SetString("\(locations[locations.count - 1].coordinate.longitude)", ForKey: .LastLongitude)
        Settings.SetString("\(locations[locations.count - 1].coordinate.latitude)", ForKey: .LastLatitude)
        Settings.SetString("\(locations[locations.count - 1].altitude)", ForKey: .LastAltitude)
        
        //This is to initialize the Apple map - it will be executed at the beginning of each instantiation
        //and if necessary when settings change in some circumstances.
        if GetInitialPositionForMap
        {
            GetInitialPositionForMap = false
            InitializeMapWithLocation(InitialLocation: locations[locations.count - 1])
            SetMapCamera(CenteredOn: locations[locations.count - 1].coordinate, AtAltitude: 500.0)
            return
        }
        
        let Period = Settings.GetInteger(ForKey: .Period)
        let NewLocation = locations[locations.count - 1]
        
        //Saving a marked location takes priority over duplication elimination.
        if SaveMarkedLocation
        {
            SaveMarkedLocation = false
            let MarkedLocation = DataPoint(WithLocation: NewLocation, IsMarked: true, Delegate: self)
            MarkedLocation.SessionID = CurrentSessionID
            DBManager.WriteDataPoint(DB: DBHandle, TrackData: MarkedLocation)
            AddNewDataPoint(MarkedLocation)
            return
        }
        
        //If we are not in a session, do nothing.
        if !Running
        {
            return
        }
        
        //If required, check for duplicates. Also, always record duplicate locations as instance counts. Marked locations are
        //not returned by `GetMostRecentLocationInSession`.
        if let PreviousLocation = GetMostRecentLocationInSession()
        {
            let Distance = NewLocation.distance(from: PreviousLocation.Location!)
            if Distance < Settings.GetDouble(ForKey: .HorizontalCloseness)
            {
                PreviousLocation.InstanceCount = PreviousLocation.InstanceCount + 1
                DBManager.UpdateLocation(DB: DBHandle, PreviousLocation)
                let VerticalDistance = abs(PreviousLocation.Location!.altitude - NewLocation.altitude)
                if VerticalDistance < Settings.GetDouble(ForKey: .VerticalCloseness)
                {
                    if Settings.GetBoolean(ForKey: .DiscardDuplicates)
                    {
                        #if DEBUG
                        print("Duplicate location skipped. [\(PreviousLocation.InstanceCount)]")
                        #endif
                        return
                    }
                }
            }
        }
        
        //Verify it is now time to save a location.
        let Now = CACurrentMediaTime()
        let FromPreviousCall = Now - LastLocationTime
        if FromPreviousCall < Double(Period)
        {
            return
        }
        
        //Save the current location.
        LastLocationTime = Now
        let SomeLocation = DataPoint(WithLocation: NewLocation, Delegate: self)
        SomeLocation.SessionID = CurrentSessionID
        DBManager.WriteDataPoint(DB: DBHandle, TrackData: SomeLocation)
        AddNewDataPoint(SomeLocation)
        LastLocation = NewLocation
    }
    
    /// Returns the most recent non-heading change location in the current session.
    /// - Note: Marked locations are not returned.
    /// - Returns: The most recent non-heading change location in the current session on success, nil if none
    ///            found.
    func GetMostRecentLocationInSession() -> DataPoint?
    {
        for Location in CurrentSession!.Locations
        {
            if Location.IsMarked
            {
                continue
            }
            if !Location.IsHeadingChange
            {
                return Location
            }
        }
        return nil
    }
    
    var LastLocationTime: Double = 0
    
    var LastLocation: CLLocation? = nil
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading: CLHeading)
    {
        if Settings.GetBoolean(ForKey: .TrackHeadings)
        {
            let HeadingTime = didUpdateHeading.timestamp
            let ActualHeading = didUpdateHeading.trueHeading
            print("New heading \(ActualHeading)° at \(Utilities.DateToString(HeadingTime))")
            if Running
            {
                let NewHeading = DataPoint(WithHeading: didUpdateHeading, Delegate: nil)
                NewHeading.SessionID = CurrentSession!.ID
                DBManager.WriteDataPoint(DB: DBHandle, TrackData: NewHeading)
                AddNewDataPoint(NewHeading)
            }
        }
    }
    
    /// A data point retreived an address and just let us know - redisplay the data table.
    /// - Parameter ThePoint: The data point that now has the address.
    /// - Parameter TheAddress: The newly retreived address.
    func HaveAddress(ThePoint: DataPoint, TheAddress: String)
    {
        DBManager.UpdateLocation(DB: DBHandle, ThePoint)
        DataPointTable.reloadData()
    }
    
    // MARK: - Apple Map functions.
    
    var CurrentAnnotations: [MKPointAnnotation] = []
    
    func InitializeMapViewer()
    {
        MapViewer.delegate = self
        MapViewer.frame = CGRect(x: 0, y: 20,
                                 width: view.frame.width,
                                 height: view.frame.height - (20.0 + 80.0))
        self.view.sendSubviewToBack(MapViewer)
        MapViewer.isZoomEnabled = true
        MapViewer.isPitchEnabled = Settings.GetBoolean(ForKey: .MapInPerspective)
        MapViewer.isScrollEnabled = true
        MapViewer.showsCompass = Settings.GetBoolean(ForKey: .ShowCompass)
        MapViewer.showsBuildings = Settings.GetBoolean(ForKey: .ShowBuildings)
        MapViewer.showsScale = Settings.GetBoolean(ForKey: .ShowScale)
        MapViewer.showsTraffic = Settings.GetBoolean(ForKey: .ShowTraffic)
        if let MapTypeString = Settings.GetString(ForKey: .MapType)
        {
            if let MapType = MapTypes(rawValue: MapTypeString)
            {
                switch MapType
                {
                    case .Hybrid:
                        MapViewer.mapType = .hybrid
                    
                    case .HybridFlyover:
                        MapViewer.mapType = .hybridFlyover
                    
                    case .MutedStandard:
                        MapViewer.mapType = .mutedStandard
                    
                    case .Satellite:
                        MapViewer.mapType = .satellite
                    
                    case .SatelliteFlyover:
                        MapViewer.mapType = .satelliteFlyover
                    
                    case .Standard:
                        MapViewer.mapType = .standard
                }
            }
            else
            {
                MapViewer.mapType = .standard
                Settings.SetString(MapTypes.Standard.rawValue, ForKey: .MapType)
            }
        }
        else
        {
            MapViewer.mapType = .standard
            Settings.SetString(MapTypes.Standard.rawValue, ForKey: .MapType)
        }
        GetInitialPositionForMap = true
    }
    
    /// Remove all map annotations.
    func RemoveAllAnnotations()
    {
        if CurrentAnnotations.isEmpty
        {
            return
        }
        MapViewer.removeAnnotations(CurrentAnnotations)
        CurrentAnnotations.removeAll()
    }
    
    var GetInitialPositionForMap = false
    
    func InitializeMapWithLocation(InitialLocation: CLLocation)
    {
        let Region = MKCoordinateRegion(center: InitialLocation.coordinate,
                                        latitudinalMeters: 10000,
                                        longitudinalMeters: 10000)
        MapViewer.setRegion(Region, animated: true)
    }
    
    /// Adds a pin annotation to the Apple map view.
    /// - Note: Heading changes are not shown on the map.
    /// - Parameter Location: The location where to add the pin.
    func UpdateMapWith(_ Location: DataPoint)
    {
        if Location.IsHeadingChange
        {
            return
        }
        if Location.IsMarked
        {
            AnnotatedPinColor = UIColor.red
        }
        else
        {
            AnnotatedPinColor = UIColor.systemIndigo
        }
        let Annotation = MKPointAnnotation()
        if let Address = Location.DecodedAddress
        {
            Annotation.title = Address
        }
        else
        {
            Annotation.title = Utilities.DateToString(Location.Location!.timestamp)
        }
        Annotation.coordinate = Location.Location!.coordinate
        MapViewer.addAnnotation(Annotation)
        CurrentAnnotations.append(Annotation)
    }
    
    var AnnotatedPinColor: UIColor = UIColor.systemIndigo
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        guard annotation is MKPointAnnotation else
        {
            return nil
        }
        let AnnotatedPin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "PinnedAnnotation")
        AnnotatedPin.pinTintColor = .some(AnnotatedPinColor)
        AnnotatedPin.animatesDrop = true
        AnnotatedPin.canShowCallout = false
        return AnnotatedPin
    }
    
    func mapViewWillStartLoadingMap(_ mapView: MKMapView)
    {
        if Settings.GetBoolean(ForKey: .ShowMapBusyIndicator)
        {
            ShowBusyIndicator()
        }
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView)
    {
        if Settings.GetBoolean(ForKey: .ShowMapBusyIndicator)
        {
            HideBusyIndicator()
        }
    }
    
    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error)
    {
        print("Failed to load map: \(error.localizedDescription)")
        if Settings.GetBoolean(ForKey: .ShowMapBusyIndicator)
        {
            ShowErrorIndicator()
        }
    }
    
    // MARK: - View selection handling.
    
    func HandleTableSelected()
    {
        DataPointTable.layer.zPosition = 1000
        MapViewer.layer.zPosition = -1000
        view.sendSubviewToBack(MapViewer)
        CurrentView = .Table
        Settings.SetString(CurrentView.rawValue, ForKey: .DataViews)
    }
    
    func HandleMapSelected()
    {
        DataPointTable.layer.zPosition = -1000
        MapViewer.layer.zPosition = 1000
        MapViewer.isUserInteractionEnabled = true
        view.bringSubviewToFront(MapViewer)
        CurrentView = .AppleMap
        Settings.SetString(CurrentView.rawValue, ForKey: .DataViews)
    }
    
    var CurrentView: DataViews = .Table
    
    @IBAction func HandleViewButtonPressed(_ sender: Any)
    {
        if ShowingViewView
        {
            CloseDrawer()
        }
        else
        {
            ShowingViewView = true
            let TheButton = sender as? UIButton
            DisplayViewDrawer(TheButton!, FromBase: BottomToolBar.frame.minY)
            self.DisableButton(self.StartButton)
            self.DisableButton(self.MarkLocationButton)
            self.DisableButton(self.SettingsButton)
        }
    }
    
    var ShowingViewView = false
    
    func DisableButton(_ Button: UIButton)
    {
        Button.isUserInteractionEnabled = false
        Button.tintColor = UIColor.systemGray
    }
    
    func EnableButton(_ Button: UIButton)
    {
        if Button == StartButton
        {
            if Running
            {
                Button.tintColor = UIColor.systemRed
            }
            else
            {
                Button.tintColor = UIColor.systemGreen
            }
        }
        else
        {
            Button.tintColor = UIColor.black
        }
        Button.isUserInteractionEnabled = true
    }
    
    // MARK: - Fabric UI variables.
    
    var BusyIndicator: MSActivityIndicatorView!
    var DrawerControls: [UIView] = []
    var DrawerControls2 = [DrawerControlDescription]()
    
    // MARK: - Interface Builder outlets.
    
    @IBOutlet weak var FetchingText: UILabel!
    @IBOutlet weak var BusyIndicatorView: UIView!
    @IBOutlet weak var SettingsButton: UIButton!
    @IBOutlet weak var MarkLocationButton: UIButton!
    @IBOutlet weak var BottomToolBar: UIView!
    @IBOutlet weak var MapViewer: MKMapView!
    @IBOutlet weak var StartButton: UIButton!
    @IBOutlet weak var DataPointTable: UITableView!
}

/// Supported data views for GPS tracks.
enum DataViews: String, CaseIterable
{
    /// Data presented in a data table.
    case Table = "Table"
    /// Data presented in an Apple Map view.
    case AppleMap = "AppleMap"
    /// Data presented in a 3D map view.
    case Map3D = "Map3D"
}
