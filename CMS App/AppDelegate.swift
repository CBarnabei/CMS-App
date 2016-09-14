//
//  AppDelegate.swift
//  CMS App v0.0.1
//
//  Created by Magnet Library on 8/21/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

var appColorProfile: CMSColorProfile {
    
    get {
        return CMSColorProfile.selectedProfile()
    }

    set {
        CMSSettingsBrain.setValueForKey("theme_color", value: newValue.themeIndex)
    }

}

let CMSSelectAnnouncementNotification = "CMSSelectAnnouncementNotification"

let syncManager = CMSSyncManager()

var launchedFromNotification = false

var initialAnnouncement: CMSAnnouncement? {
    didSet {
        NSNotificationCenter.defaultCenter().postNotificationName(CMSSelectAnnouncementNotification, object: nil)
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        if let _ = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject : AnyObject] {
            launchedFromNotification = true
        }
        
        createFileSystem()
        
        registerDefaults()
        
        updateTint()
        NSNotificationCenter.defaultCenter().addObserverForName(CMSThemeChangedNotification, object: nil, queue: nil) { _ in
            self.updateTint()
        }
        
        subscribeToCloudKit()
        registerForNotifications()
        
        print(try! CMSAnnouncementContext.fetchAnnouncements())
        
        return true
    }
    
    func createFileSystem() {
        
        let attachmentsPath = CMSFileBrain.pathInDocumentsForFileName("Attachments/")
        do {
            if !NSFileManager.defaultManager().fileExistsAtPath(attachmentsPath) {
                try CMSFileBrain.createFolder(attachmentsPath)
            }
        } catch { NSLog("\(error)"); abort() }
    }
    
    func registerDefaults() {
        var defaults = [String: AnyObject]()
        defaults["announcement_category_lunch"] = true
        defaults["announcement_category_general"] = true
        defaults["announcement_category_events"] = true
        defaults["announcement_category_birthdays"] = true
        defaults["announcement_category_sports"] = true
        defaults["announcement_category_clubs"] = true
        defaults["announcement_category_counselor"] = true
        defaults["announcement_category_principal"] = true
        defaults["announcement_category_nurse"] = true
        defaults["announcement_category_ssb"] = true
        defaults["announcement_category_graduation"] = true
        defaults["announcement_category_ptsa"] = true
        defaults["announcement_category_fcctc"] = true
        defaults["theme_color"] = 6
        defaults["last_updated"] = NSDate()
        defaults["never_updated"] = true
        defaults["hard_refresh"] = false
        CMSSettingsBrain.registerDefaults(defaults)
    }
    
    func updateTint() {
        window?.tintColor = appColorProfile.light
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        do {
            try self.saveContext()
        } catch {
            let nserror = error as NSError
            let errorString = "Unresolved error \(nserror), \(nserror.userInfo)"
            NSLog(errorString)
        }
    }
    
    
    // MARK: - Notifications
    
    func subscribeToCloudKit() {
        
        CMSSyncManager.subscribeToResources()
        
        CMSSyncManager.subscribeToAnnouncementCreation()
        //CMSSyncManager.subscribeToOtherAnnouncementCreation()
        CMSSyncManager.subscribeToAnnouncementChanges()
        //CMSSyncManager.subscribeToOtherAnnouncementChanges()
        CMSSyncManager.subscribeToAnnouncementDeletion()
        
        CMSSyncManager.subscribeToAttachments()
        
    }
    
    func registerForNotifications() {
        
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge], categories: nil)
        
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
        
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("Received remote notification: \(userInfo)")
        
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String : NSObject])
        
        if notification.notificationType == .Query {
            syncManager.processNotification(notification as! CKQueryNotification) { _, shouldRefreshAttachments in
                if shouldRefreshAttachments { syncManager.refreshAttachments() }
            }
        }
        
    }
    
    
    // MARK: - Split View
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return true }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? CMSAnnouncementViewController else { return true }
        if let nonLabel = topAsDetailController.noSelectionLabel {
            if !nonLabel.hidden {
                return true
            }
        } else { return true }
        return false
    }
    
    
    // MARK: - Core Data Stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.cms.CMS_App" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("CMS_App", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("CMS_App.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
            print("Store at \(url)")
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    /**
    Saves the applications's managed object context.
    Throws: CMSCoreDataError.SaveRequestFailed(errorString)
    */
    func saveContext() throws {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let errorString = error.errorDetails
                NSLog(errorString)
                managedObjectContext.rollback()
                throw CMSCoreDataError.SaveRequestFailed(errorMessage: errorString)
            }
        }
    }
    
}