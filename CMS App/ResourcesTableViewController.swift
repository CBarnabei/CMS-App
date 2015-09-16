//
//  ResourcesTableViewController.swift
//  CMS App
//
//  Created by Magnet Library on 8/28/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import UIKit
import SafariServices

class ResourcesTableViewController: UITableViewController, SFSafariViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        tableView.rowHeight = 44
        
        let regularSize = CGSizeMake(320, tableView.rowHeight * CGFloat(resources.count))
        let fixedSizeWhenStartingFromCompact = CGSizeMake(320, tableView.rowHeight * CGFloat(resources.count - 1))
        
        let tableSize: CGSize
        if presentingViewController!.traitCollection.horizontalSizeClass == .Regular {
            tableSize = regularSize
        } else if presentingViewController!.traitCollection.horizontalSizeClass == .Compact {
            tableSize = fixedSizeWhenStartingFromCompact
        } else {
            tableSize = regularSize
        }
        preferredContentSize = tableSize
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismiss(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Table view data source
    
    let cellID = "ResourceCell"
    let resources = ResourcePackage().resources

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // There is no need for resources to be grouped into more than 1 section
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // We should have as many rows as there are resources
        
        return resources.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellID, forIndexPath: indexPath)

        // Configure the cell...
        cell.textLabel?.text = resources[indexPath.row].label
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let URL = resources[indexPath.row].URL
        if #available(iOS 9.0, *) {
            let SFVC = SFSafariViewController(URL: URL)
            presentViewController(SFVC, animated: true, completion: nil)
        } else {
            UIApplication.sharedApplication().openURL(URL)
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    // MARK: - SafariViewController delegate
    
    @available(iOS 9.0, *)
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
