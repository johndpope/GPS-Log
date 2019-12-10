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
    MainProtocol
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
        NotificationCenter.default.addObserver(self, selector: #selector(HandleDefaultChanges), name: UserDefaults.didChangeNotification, object: nil)
        CurrentView = DataViews(rawValue: UserDefaults.standard.string(forKey: "DataViews")!)!
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
    
    func SetMapCamera(CenteredOn: CLLocationCoordinate2D, AtAltitude: Double)
    {
        let MapCamera = MKMapCamera()
        MapCamera.centerCoordinate = CenteredOn
        MapCamera.pitch = 45.0
        MapCamera.altitude = AtAltitude
        MapCamera.heading = 4.0
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
        LocationManager?.headingFilter = 1.0
        LocationManager?.startUpdatingLocation()
        LocationManager?.startUpdatingHeading()
    }
    
    /// Handle asynchronous changes to the user default values.
    /// - Note: All settings that directly effect the UI and how data are collected will be used to reset the
    ///         app as it is running. In other words, large-scale updates of the app will occur here.
    /// - Note: See: [How to determine when settings change](https://stackoverflow.com/questions/3927402/how-to-determine-when-settings-change-on-ios/33722059#33722059)
    /// - Parameter notification: The change notification.
    @objc func HandleDefaultChanges(notification: Notification)
    {
        if let _ = notification.object as? UserDefaults
        {
            if !UserDefaults.standard.bool(forKey: "ShowMapBusyIndicator")
            {
                HideBusyIndicator()
            }
            MapViewer.showsScale = UserDefaults.standard.bool(forKey: "ShowScale")
            MapViewer.showsCompass = UserDefaults.standard.bool(forKey: "ShowCompass")
            MapViewer.showsTraffic = UserDefaults.standard.bool(forKey: "ShowTraffic")
            MapViewer.showsBuildings = UserDefaults.standard.bool(forKey: "ShowBuildings")
            MapViewer.showsUserLocation = UserDefaults.standard.bool(forKey: "ShowCurrentLocation")
            var MapType = MKMapType.standard
            if let RawMapType = UserDefaults.standard.string(forKey: "MapType")
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
                UserDefaults.standard.set(MapTypes.Standard.rawValue, forKey: "MapType")
            }
            MapViewer.mapType = MapType
            LocationManager?.headingFilter = UserDefaults.standard.double(forKey: "HeadingSensitivity")
            if UserDefaults.standard.bool(forKey: "TrackHeadings")
            {
                LocationManager?.startUpdatingHeading()
            }
            let ViewValue = UserDefaults.standard.string(forKey: "DataViews")
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
        Cell.LoadData(LocationData: CurrentSession!.Locations[indexPath.row], TableWidth: DataPointTable.frame.width)
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
            CurrentSession?.SessionEnd = Date()
            RunSaveSessionDialog()
            StartButton.setImage(UIImage(systemName: "play.fill"), for: UIControl.State.normal)
            StartButton.tintColor = UIColor.systemGreen
        }
        else
        {
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
                if UserDefaults.standard.bool(forKey: "ShowAccumulatedPointsAsBadge")
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
    /// - Parameter didUpdateLocaionts: Array of new locations. We only care about the last one.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        //This is to initialize the Apple map - it is executed only once per instantiation.
        if GetInitialPositionForMap
        {
            GetInitialPositionForMap = false
            InitializeMapWithLocation(InitialLocation: locations[locations.count - 1])
            SetMapCamera(CenteredOn: locations[locations.count - 1].coordinate, AtAltitude: 500.0)
            return
        }
        
        let Period = UserDefaults.standard.integer(forKey: "Period")
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
        
        //If required, check for duplicates. Also, always record duplicate locations as instance counts.
        #if true
        if let PreviousLocation = GetMostRecentLocationInSession()
        {
            let Distance = NewLocation.distance(from: PreviousLocation.Location!)
            if Distance < UserDefaults.standard.double(forKey: "HorizontalCloseness")
            {
                PreviousLocation.InstanceCount = PreviousLocation.InstanceCount + 1
                DBManager.UpdateLocation(DB: DBHandle, PreviousLocation)
                let VerticalDistance = abs(PreviousLocation.Location!.altitude - NewLocation.altitude)
                if VerticalDistance < UserDefaults.standard.double(forKey: "VerticalCloseness")
                {
                    if UserDefaults.standard.bool(forKey: "DiscardDuplicates") && LastLocation != nil
                    {
                        #if DEBUG
                        print("Duplicate location skipped. [\(PreviousLocation.InstanceCount)]")
                        #endif
                        return
                    }
                }
            }
        }
        #else
        if UserDefaults.standard.bool(forKey: "DiscardDuplicates") && LastLocation != nil
        {
            let Distance = NewLocation.distance(from: LastLocation!)
            if Distance < UserDefaults.standard.double(forKey: "HorizontalCloseness")
            {
                let VerticalDistance = abs(LastLocation!.altitude - NewLocation.altitude)
                if VerticalDistance < UserDefaults.standard.double(forKey: "VerticalCloseness")
                {
                    print("Duplicate location skipped.")
                    return
                }
            }
        }
        #endif
        
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
    /// - Returns: The most recent non-heading change location in the current session on success, nil if none
    ///            found.
    func GetMostRecentLocationInSession() -> DataPoint?
    {
        for Location in CurrentSession!.Locations
        {
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
        if UserDefaults.standard.bool(forKey: "TrackHeadings")
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
    
    /*
    @IBSegueAction func HandleSavedSessionsInstantiation(_ coder: NSCoder) -> SessionList?
    {
        let SessionController = SessionList(coder: coder)
        SessionController?.Main = self
        return SessionController
    }
 */
    
    // MARK: - Apple Map functions.
    
    var CurrentAnnotations: [MKPointAnnotation] = []
    
    func InitializeMapViewer()
    {
        MapViewer.delegate = self
        MapViewer.frame = CGRect(x: 0, y: 20,
                                 width: view.frame.width,
                                 height: view.frame.height - (20.0 + 80.0))
        self.view.sendSubviewToBack(MapViewer)
        MapViewer.isPitchEnabled = true
        MapViewer.showsCompass = true
        MapViewer.showsBuildings = true
        MapViewer.showsScale = true
        MapViewer.showsTraffic = true
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
        if UserDefaults.standard.bool(forKey: "ShowMapBusyIndicator")
        {
        ShowBusyIndicator()
        }
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView)
    {
        if UserDefaults.standard.bool(forKey: "ShowMapBusyIndicator")
        {
        HideBusyIndicator()
        }
    }
    
    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error)
    {
        print("Failed to load map: \(error.localizedDescription)")
        if UserDefaults.standard.bool(forKey: "ShowMapBusyIndicator")
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
        UserDefaults.standard.set(CurrentView.rawValue, forKey: "DataViews")
    }
    
    func HandleMapSelected()
    {
        DataPointTable.layer.zPosition = -1000
        MapViewer.layer.zPosition = 1000
        MapViewer.isUserInteractionEnabled = true
        view.bringSubviewToFront(MapViewer)
        CurrentView = .AppleMap
        UserDefaults.standard.set(CurrentView.rawValue, forKey: "DataViews")
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
