//
//  MasterViewController.swift
//  CMS App
//
//  Created by Magnet Library on 8/21/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import UIKit
import CoreData

class CMSAnnouncementTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var progressView: CMSProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        registerForNotifications()
        
        toolbarItems![1] = createProgressBarItem()
        
        if CMSSettingsBrain.valueForKey("hard_refresh") as! Bool || CMSSettingsBrain.valueForKey("never_updated") as! Bool {
            refreshFromCloud()
            CMSSettingsBrain.setValueForKey("hard_refresh", value: false)
        } else {
            syncFromCloud()
        }
        
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateProgessBar(progress: Float) {
        dispatch_async(dispatch_get_main_queue()) {
            self.progressView.progress = progress
        }
    }
    
    func createProgressBarItem() -> UIBarButtonItem {
        return UIBarButtonItem(customView: createProgressView())
    }
    
    func createProgressView() -> CMSProgressView {
        
        let toolbar = navigationController!.toolbar!
        let toolbarWidth = toolbar.bounds.width
        let toolbarHeight = toolbar.bounds.height
        
        let progressView = CMSProgressView()
        progressView.bounds = CGRect(x: 0, y: 0, width: toolbarWidth, height: toolbarHeight)
        
        self.progressView = progressView
        return progressView
        
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showAnnouncement" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
            let announcement = self.fetchedResultsController.objectAtIndexPath(indexPath) as! CMSAnnouncement
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! CMSAnnouncementViewController
                controller.titleItem = announcement.title
                controller.categoryItem = announcement.category!
                controller.bodyItem = announcement.formattedText
                controller.announcement = announcement
                controller.attachments = announcement.attachments.allObjects as! [CMSAttachment]
            }
        }

    }

    // MARK: - Table View
    
    let moc = CMSCoreDataBrain.context

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections!.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let categoryIndex = Int(self.fetchedResultsController.sections![section].name)!
        let categoryKey = CMSSettingsBrain.categoryKeys[categoryIndex]
        let title = CMSSettingsBrain.categoriesForKeys[categoryKey]
        return title
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("announcementCell", forIndexPath: indexPath) as! CMSAnnouncementTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    func configureCell(cell: CMSAnnouncementTableViewCell, atIndexPath indexPath: NSIndexPath) {
        let announcement = self.fetchedResultsController.objectAtIndexPath(indexPath) as! CMSAnnouncement
        cell.title.text = announcement.title!
    }
    
    
    // MARK: - Refresh
    
    func syncFromCloud() {
        
        progressView.resetProgress()
        
        let timeout = ScheduledClosure.scheduleClosureWithTimeInterval(10, repeats: false, firesDuringCommonProcesses: true, closure: { _ in
            self.refreshControl?.endRefreshing()
        })
        
        syncManager.syncChanges(progressHandler: { progressIndex in
            timeout.cancel()
            dispatch_async(dispatch_get_main_queue()) {
                let progress = Float(progressIndex) / 70
                self.progressView.progress = progress <= 0.95 ? progress : 0.95
            }
            }, completionHandler: { error in
                timeout.cancel()
                if let syncError = error {
                    NSLog(syncError.errorDetails)
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    ScheduledClosure.scheduleClosureWithTimeInterval(1, repeats: false) { _ in
                        self.progressView.finishProgress()
                        self.progressView.updateDate()
                        self.progressView.updating = false
                        let refreshControl = self.refreshControl!
                        if refreshControl.refreshing { refreshControl.endRefreshing() }
                    }
                }
        })
        
    }
    
    func refreshFromCloud() {
        
        progressView.resetProgress()
        
        let timeout = ScheduledClosure.scheduleClosureWithTimeInterval(15, repeats: false, firesDuringCommonProcesses: true, closure: { _ in
            self.refreshControl?.endRefreshing()
        })
        
        syncManager.refreshResources(progressBlock: { resourceCount in
            timeout.cancel()
            if resourceCount <= 9 {
                self.updateProgessBar(Float(resourceCount) / 10.0 / 4.0)
            }
            
        }) { _ in
            syncManager.refreshAnnouncements(progressBlock: { announcementCount in
                timeout.cancel()
                if announcementCount <= 15 {
                    self.updateProgessBar(0.25 + Float(announcementCount) / (8.0 / 0.9) / 4.0)
                }
                
            }) { _ in
                syncManager.refreshAttachments(progressBlock: { attachmentCount in
                    timeout.cancel()
                    if attachmentCount <= 5 {
                        self.updateProgessBar(0.5 + Float(attachmentCount) / (5.0 / 0.9) / 2.0)
                    }
                    
                }) { error in
                    timeout.cancel()
                    dispatch_async(dispatch_get_main_queue()) {
                        
                        if let syncError = error {
                            NSLog(syncError.errorDetails)
                        }
                        
                        ScheduledClosure.scheduleClosureWithTimeInterval(1, repeats: false) { _ in
                            self.progressView.finishProgress()
                            self.progressView.updateDate()
                            self.progressView.updating = false
                            let refreshControl = self.refreshControl!
                            if refreshControl.refreshing { refreshControl.endRefreshing() }
                        }
                    }
                }
            }
        }
        
    }
    
    @IBAction func refresh() {
        let refreshControl = self.refreshControl!
        if refreshControl.refreshing && !CMSSyncManager.isWorking {
            print("refreshing...")
            syncFromCloud()
            tableView.reloadData()
        } else { refreshControl.endRefreshing() }
    }
    
    func hardRefreshIfNeeded() {
        
        if CMSSettingsBrain.valueForKey("hard_refresh") as! Bool {
            refreshFromCloud()
        }
        
    }
    

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("CMSAnnouncement", inManagedObjectContext: moc)
        fetchRequest.entity = entity
        
        
        // Predicate
        fetchRequest.predicate = createPredicate()
        
        // Edit the sort key as appropriate.
        let sectionSortDescriptor = NSSortDescriptor(key: "categoryIndex", ascending: true)
        let rowSortDescriptor = NSSortDescriptor(key: "startDate", ascending: false)
        
        fetchRequest.sortDescriptors = [sectionSortDescriptor, rowSortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: "categoryIndex", cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            NSLog("\(error.errorDetails)")
            let alertVC = UIAlertController(title: "Oops", message: "Announcements could not be retrieved. Please try again.", preferredStyle: .Alert)
            let okButton = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
            alertVC.addAction(okButton)
            presentViewController(alertVC, animated: true, completion: nil)
        }
        
        return _fetchedResultsController!
    }
    
    
    func createPredicate(newDefaults: [String: AnyObject]? = nil) -> NSPredicate {
        
        let beginningOfToday = NSDate().dateRetainingComponents(unitFlags: [.Year, .Month, .Day])
        let endOfToday = NSDate().dateRetainingComponents(unitFlags: [.Year, .Month, .Day]).dateByAddingTimeInterval(86400)
        
        let datePredicate = NSPredicate(format: "startDate <= %@ AND endDate >= %@", endOfToday, beginningOfToday)
        let categoryPredicate = CMSBrain.predicateForSelectedAnnouncementCategories(newDefaults)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, categoryPredicate])
        
    }
    
    var _fetchedResultsController: NSFetchedResultsController? = nil

//    func controllerWillChangeContent(controller: NSFetchedResultsController) {
//        self.tableView.beginUpdates()
//    }

//    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
//        switch type {
//        case .Insert:
//            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
//        case .Delete:
//            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
//        default:
//            return
//        }
//    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
//        switch type {
//            case .Insert:
//                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
//            case .Delete:
//                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
//            case .Update:
//                self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)! as! CMSAnnouncementTableViewCell, atIndexPath: indexPath!)
//            case .Move:
//                self.tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
//        }
        tableView.reloadData()
        progressView.updateDate()
    }

//    func controllerDidChangeContent(controller: NSFetchedResultsController) {
//        self.tableView.endUpdates()
//    }
    
    var needsRefresh = false
    
    
    // MARK: - Notifications
    
    var selectedInitial = false
    
    func registerForNotifications() {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CMSAnnouncementTableViewController.settingsChanged(_:)), name: CMSSettingsChangedNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserverForName(CMSSelectAnnouncementNotification, object: nil, queue: nil, usingBlock: { _ in
            if !self.selectedInitial {
                if let announcement = initialAnnouncement, let indexPath = self.fetchedResultsController.indexPathForObject(announcement) {
                    self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Middle)
                    self.performSegueWithIdentifier("showAnnouncement", sender: nil)
                }
                self.selectedInitial = true
            }
        })
        
    }
    
    func settingsChanged(notification: NSNotification) {
        do {
            fetchedResultsController.fetchRequest.predicate = createPredicate((notification.userInfo! as! [String: AnyObject]))
            try fetchedResultsController.performFetch()
            tableView.reloadData()
            print(NSUserDefaults.standardUserDefaults().boolForKey("announcement_category_clubs"))
        } catch {
            NSLog("Failed to reset announcement table on category preference change.")
        }
    }
    

    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
         // In the simplest, most efficient, case, reload the table view.
         self.tableView.reloadData()
     }
     */

}
