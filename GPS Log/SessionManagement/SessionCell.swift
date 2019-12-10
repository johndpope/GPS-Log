//
//  SessionCell.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/6/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import SQLite3

/// Displays session data in a table view.
class SessionCell: UITableViewCell
{
    /// Cell height.
    public static let CellHeight: CGFloat = 60.0
    
    /// Default initializer.
    /// - Parameter style: Cell style.
    /// - Parameter reuseIdentifier: Identifier for cell reuse.
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        InitializeUI()
    }
    
    /// Initializer.
    /// - Parameter coder: See Apple documentation.
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        InitializeUI()
    }
    
    /// Initialize the UI. Create controls.
    func InitializeUI()
    {
        self.selectionStyle = .none
        self.accessoryType = .disclosureIndicator
        NameLabel = UILabel(frame: CGRect(x: 5, y: 2, width: 100, height: 23))
        NameLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
        contentView.addSubview(NameLabel)
        CountLabel = UILabel(frame: CGRect(x: 5, y: 30, width: 100, height: 20))
        CountLabel.font = UIFont.systemFont(ofSize: 12.0)
        contentView.addSubview(CountLabel)
        DateLabel = UILabel(frame: CGRect(x: 101, y: 20, width: 80, height: 20))
        DateLabel.font = UIFont.systemFont(ofSize: 14.0)
        contentView.addSubview(DateLabel)
    }
    
    var NameLabel: UILabel!
    var DateLabel: UILabel!
    var CountLabel: UILabel!
    
    /// Update the size and locations of the controls based on the width of the table control.
    func UpdateControlsWith(Width: CGFloat)
    {
        NameLabel.frame = CGRect(x: NameLabel.frame.minX,
                                 y: NameLabel.frame.minY,
                                 width: Width / 2.0,
                                 height: NameLabel.frame.height)
        CountLabel.frame = CGRect(x: CountLabel.frame.minX,
                                  y: CountLabel.frame.minY,
                                  width: Width / 2.0,
                                  height: CountLabel.frame.height)
        DateLabel.frame = CGRect(x: (Width / 2.0) + 5.0,
                                 y: DateLabel.frame.minY,
                                 width: (Width / 2.0) - (5.0 + 30.0),
                                 height: DateLabel.frame.height)
    }
    
    /// Load data for the cell.
    /// - Parameter Session: The session whose data will be displayed.
    /// - Parameter Handle: Database handle. Needed to get the number of entries for the session.
    /// - Parameter TableWidth: Width of the parent table view control.
    /// - Parameter UseTestData: If true, test data will be used.
    func LoadData(_ Session: SessionData, Handle: OpaquePointer?, TableWidth: CGFloat, UseTestData: Bool = false)
    {
        UpdateControlsWith(Width: TableWidth)
        self.SessionID = Session.ID
        NameLabel.text = Session.Name
        DateLabel.text = Utilities.DateToString(Session.SessionStart)
        let Count = DBManager.EntryCountForSession(DB: Handle, SessionID: Session.ID, UseTestData: UseTestData)!
        CountLabel.text = "\(Count) locations"
    }
    
    public var SessionID: UUID!
}
