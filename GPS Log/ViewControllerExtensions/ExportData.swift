//
//  ExportData.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/6/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

extension ViewController: UIActivityItemSource
{
    func ExportDatabase()
    {
        let Items: [Any] = [self]
        let ACV = UIActivityViewController(activityItems: Items, applicationActivities: nil)
        ACV.popoverPresentationController?.sourceView = self.view
        ACV.popoverPresentationController?.sourceRect = self.view.frame
        ACV.popoverPresentationController?.canOverlapSourceViewRect = true
        ACV.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        self.present(ACV, animated: true, completion: nil)
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return String()
    }
    
    /// Returns the subject line for possible use when exporting the gradient image.
    /// - Parameter activityViewController: Not used.
    /// - Parameter subjectForActivityType: Not used.
    /// - Returns: Subject line.
    public func activityViewController(_ activityViewController: UIActivityViewController,
                                       subjectForActivityType activityType: UIActivity.Type?) -> String
    {
        return "GPS Log Sqlite Database"
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any?
    {
        let ID = CurrentSessionID
        let Lines = DBManager.GetSessionDataAsXML(DB: DBHandle, SessionID: ID)
        var Final = ""
        for Line in Lines
        {
            Final.append(Line + "\n")
        }
        
        switch activityType!
        {
            case .mail:
            return Final
            
            case .airDrop:
            return Final
            
            default:
            return nil
        }
    }
}
