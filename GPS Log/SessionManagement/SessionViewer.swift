//
//  SessionViewer.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/7/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import SQLite3

class SessionViewer: UIViewController, UITableViewDelegate, UITableViewDataSource, SessionViewerProtocol
{
    weak var Main: MainProtocol? = nil
    weak var SessionDelegate: SessionViewerProtocol? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        DBHandle = Main?.Handle()
        SessionID = (SessionDelegate?.GetSessionID())!
        UseTestData = (SessionDelegate?.GetUseTestData())!
        EntryTable.layer.borderColor = UIColor.black.cgColor
        CurrentSession = DBManager.RetreiveSession(DB: DBHandle, SessionID: SessionID, UseTestData: UseTestData)
        if CurrentSession == nil
        {
            fatalError("Could not retrieve \(SessionID)")
        }
        EntryTable.reloadData()
        NameTextBox.text = CurrentSession!.Name
    }
    
    var UseTestData: Bool = false
    var DBHandle: OpaquePointer? = nil
    var SessionID: UUID = UUID()
    var CurrentSession: SessionData? = nil
    
    func GetSessionID() -> UUID
    {
        return SessionID
    }
    
    func GetUseTestData() -> Bool
    {
        return UseTestData
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return CurrentSession!.Locations.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return LocationCell.CellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let Cell = LocationCell(style: .default, reuseIdentifier: "LocationCellForSession")
        Cell.LoadData(LocationData: CurrentSession!.Locations[indexPath.row], TableWidth: EntryTable.frame.width,
                      MainFontSize: 14.0, SubFontSize: 8.0)
        return Cell
    }
    
    @IBAction func HandleDeleteSessionPressed(_ sender: Any)
    {
    }
    
    @IBAction func HandleBackButton(_ sender: Any)
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func HandleTextAction(_ sender: Any)
    {
    }
    
    @IBAction func HandleNameSetButtonPressed(_ sender: Any)
    {
    }
    
    @IBSegueAction func HandleMapViewInstantiated(_ coder: NSCoder) -> MapViewController?
    {
        let MapViewC = MapViewController(coder: coder)
        MapViewC?.SessionDelegate = self
        MapViewC?.Main = Main
        return MapViewC
    }
    
    @IBOutlet weak var NameTextBox: UITextField!
    @IBOutlet weak var EntryTable: UITableView!
}
