//
//  InfoView.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/7/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import SQLite3

class InfoView: UITableViewController
{
    weak var Main: MainProtocol? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        DBHandle = Main?.Handle()
        PopulateTable()
    }
    
    var DBHandle: OpaquePointer? = nil
    
    func PopulateTable()
    {
        let SessionCount = DBManager.GetSessionCount(DB: DBHandle)!
        let EntryCount = DBManager.GetEntryCount(DB: DBHandle)!
            SessionCountLabel.text = "Sessions: \(SessionCount)"
        EntryCountLabel.text = "Entries: \(EntryCount)"
        if SessionCount > 0 && EntryCount > 0
        {
            let Mean: Double = Double(EntryCount) / Double(SessionCount)
            let MeanString = Utilities.RoundedString(Value: Mean, Precision: 2)
            EntriesPerSessionLabel.text = "Mean entries per session: \(MeanString)"
        }
        else
        {
            EntriesPerSessionLabel.text = ""
        }
    }
    
    @IBOutlet weak var EntriesPerSessionLabel: UILabel!
    @IBOutlet weak var EntryCountLabel: UILabel!
    @IBOutlet weak var SessionCountLabel: UILabel!
}
