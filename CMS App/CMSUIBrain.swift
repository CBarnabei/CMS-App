//
//  CMSUIBrain.swift
//  Temp CMS Now
//
//  Created by Matthew Benjamin on 1/28/16.
//  Copyright © 2016 CMS. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func presentAlertWithOkayButton(alertTitle: String, message: String, completionHandler: (() -> ())? ) {
        
        let okayAction = UIAlertAction(title: "Okay", style: .Default, handler: nil)
        
        presentAlertWithActions(alertTitle, message: message, actions: [okayAction], completionHandler: completionHandler)
        
    }
    
    func presentAlertWithActions(alertTitle: String, message: String, actions: [UIAlertAction], completionHandler: (() -> ())? ) {
        
        let alert = UIAlertController(title: alertTitle, message: message, preferredStyle: .Alert)
        
        for action in actions {
            alert.addAction(action)
        }
        
        presentViewController(alert, animated: true, completion: completionHandler)
        
    }
    
}

extension UITableViewController {
    
    func sizeTable(rowCount rowCount: Int, rowHeight: CGFloat = 44) {
        
        let horizontalSizeOfParent = presentingViewController?.traitCollection.horizontalSizeClass
        
        tableView.rowHeight = rowHeight
        
        let regularSize = CGSizeMake(320, tableView.rowHeight * CGFloat(rowCount))
        let fixedSizeWhenStartingFromCompact = CGSizeMake(320, tableView.rowHeight * CGFloat(rowCount - 1))
        
        let tableSize: CGSize
        if horizontalSizeOfParent == .Regular {
            tableSize = regularSize
        } else if horizontalSizeOfParent == .Compact {
            tableSize = fixedSizeWhenStartingFromCompact
        } else {
            tableSize = regularSize
        }
        preferredContentSize = tableSize
    }
    
}

extension UIViewController {
    
    func setBarForPopover() {
        // Navigation Bar
        let horizontalSizeOfParent = presentingViewController?.traitCollection.horizontalSizeClass
        navigationController?.navigationBarHidden = horizontalSizeOfParent == .Regular
    }
    
}