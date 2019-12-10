//
//  SessionList.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/6/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import SQLite3

class SessionList: UITableViewController, SessionViewerProtocol
{
    weak var Main: MainProtocol? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        if Main == nil
        {
            //The main protocol is nil (we were instantiated faster than the delegate was set) so we need
            //to pull the delegate value from the parent.
            let Parent = self.parent as? SessionsNavigator
            Main = Parent?.Main
        }
        DBHandle = Main?.Handle()
        SessionList = DBManager.SessionList(DB: DBHandle)
        tableView.reloadData()
    }
    
    func GetSessionID() -> UUID
    {
        return SelectedSessionID
    }
    
    func GetUseTestData() -> Bool
    {
        return UsingTestData
    }
    
    var SessionList: [SessionData] = []
    var DBHandle: OpaquePointer? = nil
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return SessionCell.CellHeight
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return SessionList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let Cell = SessionCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "SessionCell")
        Cell.LoadData(SessionList[indexPath.row], Handle: DBHandle, TableWidth: self.view.frame.width, UseTestData: UsingTestData)
        return Cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        SelectedSessionID = SessionList[indexPath.row].ID
        let Storyboard = UIStoryboard(name: "Main", bundle: nil)
        let VC = Storyboard.instantiateViewController(identifier: "SessionViewer") as SessionViewer
        VC.Main = Main
        VC.SessionDelegate = self
        self.navigationController?.show(VC, sender: nil)
    }
    
    var SelectedSessionID: UUID = UUID()
    
    @IBAction func HandleDonePressed(_ sender: Any)
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBSegueAction func HandleInstantiateInfoViewer(_ coder: NSCoder) -> InfoView?
    {
        let IView = InfoView(coder: coder)
        IView?.Main = Main
        return IView
    }

    @IBAction func HandleTestDataSwap(_ sender: Any)
    {
        if UsingTestData
        {
            UsingTestData = false
                    SessionList = DBManager.SessionList(DB: DBHandle)
        }
        else
        {
            UsingTestData = true
            SessionList = DBManager.SessionList(DB: DBHandle, UseTestData: true)
        }
        tableView.reloadData()
    }
    
    var UsingTestData = false
    
    @IBAction func HandleDeleteEverythingButton(_ sender: Any)
    {
        let Alert = UIAlertController(title: "Delete All Data",
                                      message: "Do you really want to delete all of your data? If you have not backed up your tracks, they will be unrecoverable.",
                                      preferredStyle: .alert)
        Alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler:
            {
                _ in
                self.ConfirmDeletion()
        }))
        Alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        self.present(Alert, animated: true, completion: nil)
    }
    
    func ConfirmDeletion()
    {
        let SessionCount = DBManager.GetSessionCount(DB: DBHandle)!
        let EntryCount = DBManager.GetEntryCount(DB: DBHandle)!
        let ConfirmString = "Do you really want to delete \(SessionCount) sessions and \(EntryCount) entries? You can delete individual sessions by tapping on the session and pressing the red X."
        let Alert = UIAlertController(title: "Confirm Data Deletion", message: ConfirmString, preferredStyle: .alert)
        Alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler:
            {
                _ in
                self.DeleteEverything()
        }))
        Alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(Alert, animated: true, completion: nil)
    }
    
    func DeleteEverything()
    {
        
    }

}
