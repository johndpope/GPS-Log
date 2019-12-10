//
//  MapViewController.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/7/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import SQLite3

class MapViewController: UIViewController
{
    weak var SessionDelegate: SessionViewerProtocol? = nil
    weak var Main: MainProtocol? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        DBHandle = Main?.Handle()
        SessionID = SessionDelegate?.GetSessionID()
        UseTestData = (SessionDelegate?.GetUseTestData())!
        CurrentSession = DBManager.RetreiveSession(DB: DBHandle, SessionID: SessionID, UseTestData: UseTestData)
        let SessionName = CurrentSession.Name
        if !SessionName.isEmpty
        {
            self.title = SessionName
        }
        MapDisplay.DisplaySession(CurrentSession)
    }
    
    var UseTestData: Bool = false
    var CurrentSession: SessionData!
    var SessionID: UUID!
    var DBHandle: OpaquePointer? = nil
    
    @IBAction func HandleShareImage(_ sender: Any)
    {
    }
    
    @IBAction func HandleGlobeButton(_ sender: Any)
    {
    }
    
    @IBAction func HandleInfoButton(_ sender: Any)
    {
    }
    
    @IBOutlet weak var MapDisplay: MapView!
}
