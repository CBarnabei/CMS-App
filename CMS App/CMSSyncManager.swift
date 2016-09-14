//
//  CMSSyncManager.swift
//  Temp CMS Now
//
//  Created by Matthew Benjamin on 2/4/16.
//  Copyright © 2016 CMS. All rights reserved.
//

import CloudKit
import CoreData
import UIKit

let CMSSyncErrorNotification = "CMSSyncErrorNotification"
let CMSCategoryChangedNotification = "CMSCategoryChangedNotification"
let CMSAttachmentsRefreshedNotification = "CMSAttachmentsRefreshedNotification"

let CMSAnnouncementKey = "CMSAnnouncementKey"

class CMSSyncManager {
    
    static let defaultContainer = CKContainer(identifier: "iCloud.com.chambersburg.cms-now")
    
    static var isWorking = false
    
    init() {
        CMSSyncManager.defaultContainer.accountStatusWithCompletionHandler { status, error in
            NSLog("Account status = \(status.rawValue)")
        }
    }
    
    func syncChanges(progressHandler progressHandler: ((Int) -> Void)?, completionHandler: ((ErrorType?) -> Void)?) {
        
        let fetchChanges = CKFetchNotificationChangesOperation(previousServerChangeToken: changeToken)
        
        var shouldRefetchAttachments = false
        
        var index = 0
        fetchChanges.notificationChangedBlock = { notification in
            index += 1
            progressHandler?(index)
            if notification.notificationType == .Query {
                self.processNotification(notification as! CKQueryNotification, completion: { error, shouldRefreshAttachments in
                    
                    if shouldRefreshAttachments { shouldRefetchAttachments = true }
                    
                    if let processingError = error {
                        NSLog(processingError.errorDetails)
                    }
                    
                })
            }
        }
        
        fetchChanges.fetchNotificationChangesCompletionBlock = { newChangeToken, error in
            if shouldRefetchAttachments { self.refreshAttachments() }
            dispatch_sync(dispatch_get_main_queue()) {
                
                completionHandler?(error)
                if error == nil {
                    self.changeToken = newChangeToken
                    
                    let resetBadge = CKModifyBadgeOperation(badgeValue: 0)
                    
                    resetBadge.modifyBadgeCompletionBlock = { error in
                        if let badgeError = error {
                            NSLog(badgeError.errorDetails)
                        } else {
                            UIApplication.sharedApplication().applicationIconBadgeNumber = 0
                        }
                    }
                    
                    CMSSyncManager.defaultContainer.addOperation(resetBadge)
                    
                }
            }
        }
        
        CMSSyncManager.defaultContainer.addOperation(fetchChanges)
        
    }
    
    private let publicDatabase = CMSSyncManager.defaultContainer.publicCloudDatabase
    
    private var retryIn: NSTimeInterval = 1
    
    func processNotification(notification: CKQueryNotification, completion: ((ErrorType?, Bool) -> Void)? = nil ) {
        // Careful, some properties may have been dropped from the notification object if it was too large
        
        CMSSyncManager.isWorking = true
        
        if let recordID = notification.recordID {
            
            // Handle deleted records
            if notification.queryNotificationReason == .RecordDeleted {
                if NSOperationQueue.currentQueue() == NSOperationQueue.mainQueue() {
                    self.recordIDDeleted(recordID)
                } else {
                    dispatch_sync(dispatch_get_main_queue()) {
                        self.recordIDDeleted(recordID)
                    }
                }
                return
            }
            
            // Handle created and changed records
            publicDatabase.fetchRecordWithID(recordID) { record, error in
                
                // Handle any error
                if let fetchError = error {
                    NSLog("Error fetching record with record ID: \(error)")
                    self.handleErrors(fetchError) {
                        self.processNotification(notification, completion: completion)
                    }
                    completion?(fetchError, false)
                    return
                }
                
                var shouldRefreshAttachments = false
                
                if record != nil {
                    
                    // Handle created records
                    if notification.queryNotificationReason == .RecordCreated {
                        dispatch_sync(dispatch_get_main_queue()) {
                            switch record!.recordType {
                            case "Resources": self.resourceCreated(record!)
                            case "Announcements": self.announcementCreated(record!)
                                if launchedFromNotification {
                                    let initial = try? CMSAnnouncementContext.announcementForRecordID(record!.recordID)
                                    if let initial = initial {
                                        initialAnnouncement = initial
                                    }
                                }
                            case "Attachments": shouldRefreshAttachments = true
                            default: return
                            }
                        }
                    }
                    
                    // Handle modified records
                    if notification.queryNotificationReason == .RecordUpdated {
                        dispatch_sync(dispatch_get_main_queue()) {
                            switch record!.recordType {
                            case "Resources": self.resourceUpdated(record!)
                            case "Announcements": self.announcementUpdated(record!)
                                if launchedFromNotification {
                                    let initial = try? CMSAnnouncementContext.announcementForRecordID(record!.recordID)
                                    if let initial = initial {
                                        initialAnnouncement = initial
                                    }
                                }
                            case "Attachments": shouldRefreshAttachments = true
                            default: return
                            }
                        }
                    }
                    
                }
                
                completion?(nil, shouldRefreshAttachments)
                
            }
            
        }
        
        if let notificationID = notification.notificationID {
            let markRead = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: [notificationID])
            markRead.markNotificationsReadCompletionBlock = { _, error in
                if let markError = error {
                    NSLog(markError.errorDetails)
                }
            }
            CMSSyncManager.defaultContainer.addOperation(markRead)
        }
        
        CMSSyncManager.isWorking = false
        
    }
    
    private func recordIDDeleted(recordID: CKRecordID) {
        
        do {
            try CMSResourceContext.deleteResource(recordID)
        } catch CMSResourceError.IDNotFound {
            do {
                try CMSAttachmentContext.deleteAttachment(recordID)
            } catch CMSAttachmentError.IDNotFound {
                do {
                    try CMSAnnouncementContext.deleteAnnouncement(recordID)
                } catch { NSLog(error.errorDetails) }
            } catch { NSLog(error.errorDetails) }
        } catch { NSLog(error.errorDetails) }
        
    }
    
    private func resourceCreated(resource: CKRecord) {
        
        do {
            try CMSResourceContext.addResource(resource)
        } catch { return NSLog(error.errorDetails) }
        
    }
    
    private func resourceUpdated(resource: CKRecord) {
        do {
            try CMSResourceContext.changeLabel(resource["Label"] as! String, forRecordID: resource.recordID)
        } catch { NSLog(error.errorDetails) }
        
        do {
            try CMSResourceContext.changeURL(resource["URL"] as! String, forRecordID: resource.recordID)
        } catch { error.errorDetails }
    }
    
    private func announcementCreated(announcement: CKRecord) {
        
        do {
            
//            // Guard against dates
//            let startDate = announcement["StartDate"] as! NSDate
//            guard startDate.compare(NSDate()) == NSComparisonResult.OrderedAscending else { return }
//            
//            // Guard against past end date
//            let endDate = announcement["EndDate"] as! NSDate
//            let today = NSDate().dateRetainingComponents(unitFlags: [.Year, .Month, .Day])
//            let comparison = endDate.dateRetainingComponents(unitFlags: [.Year, .Month, .Day]).compare(today)
//            guard comparison == .OrderedDescending || comparison == .OrderedSame else { return }
            
            try CMSAnnouncementContext.addAnnouncement(announcement)
        } catch { NSLog(error.errorDetails); return }
        
    }
    
    private func announcementUpdated(announcement: CKRecord) {
        do {
            try CMSAnnouncementContext.changeTitle(announcement["Title"] as! String, forRecordID: announcement.recordID)
        } catch CMSAnnouncementError.IDNotFound {
            announcementCreated(announcement)
        } catch { NSLog(error.errorDetails) }
        
        do {
            try CMSAnnouncementContext.changeBody(announcement["BodyText"] as! String, forRecordID: announcement.recordID)
        } catch { NSLog(error.errorDetails) }
        
        do {
            try CMSAnnouncementContext.changeCategory(newCategoryKey: announcement["Category"] as! String, forRecordID: announcement.recordID)
        } catch { NSLog(error.errorDetails) }
        
        do {
            try CMSAnnouncementContext.changeStartDate(announcement["StartDate"] as! NSDate, forRecordID: announcement.recordID)
        } catch { NSLog(error.errorDetails) }
        
        do {
            try CMSAnnouncementContext.changeEndDate(announcement["EndDate"] as! NSDate, forRecordID: announcement.recordID)
        } catch { NSLog(error.errorDetails) }
        
        if let foundAnnouncementObj = try? CMSAnnouncementContext.announcementForRecordID(announcement.recordID), let announcementObj = foundAnnouncementObj {
            NSNotificationCenter.defaultCenter().postNotificationName(CMSCategoryChangedNotification, object: nil, userInfo: [CMSAnnouncementKey : announcementObj])
        }
    }
    
    private func attachmentCreated(attachment: CKRecord) {
        
        do {
            try CMSAttachmentContext.addAttachment(attachment)
            try CMSAttachmentContext.addToAnnouncement(attachmentRecord: attachment)
        } catch { NSLog(error.errorDetails); return }
        
    }
    
    private func attachmentUpdated(attachment: CKRecord) {
        do {
            try CMSAttachmentContext.changeTitle(attachment["Title"] as! String, forRecordID: attachment.recordID)
        } catch { NSLog(error.errorDetails) }
    }
    
    func refreshResources(progressBlock progressBlock: ((Int) -> ())? = nil, completion: ((ErrorType?) -> ())? = nil ) {
        
        CMSSyncManager.isWorking = true
        
        var resourcesDeleted = false
        
        let query = CKQuery(recordType: "Resources", predicate: NSPredicate(format: "TRUEPREDICATE"))
        
        let queryOperation = CKQueryOperation(query: query)
        
        var count = 0
        
        queryOperation.recordFetchedBlock = { resource in
            
            var `return` = false
            dispatch_sync(dispatch_get_main_queue()) {
                count += 1
                progressBlock?(count)
                
                if !resourcesDeleted {
                    do {
                        try CMSResourceContext.deleteAll()
                    } catch { NSLog(error.errorDetails); `return` = true }
                    resourcesDeleted = true
                }
                
                if `return` { return }
                
                self.resourceCreated(resource)
            }
            
        }
        
        queryOperation.queryCompletionBlock = { cursor, error in
            
            if let queryError = error {
                NSLog((queryError as ErrorType).errorDetails)
                self.handleErrors(queryError, retry: {
                    self.refreshResources(progressBlock: progressBlock, completion: completion)
                })
            } else { self.resetRetry() }
            
            CMSSyncManager.isWorking = false
            
            completion?(error)
            
        }
        
        publicDatabase.addOperation(queryOperation)
        
        ScheduledClosure.scheduleClosureWithTimeInterval(0.5, tolerance: 0.1, repeats: false) { _ in
            if !queryOperation.finished {
                CMSSyncManager.isWorking = false
                completion?(nil)
            }
        }
        
    }
    
    func refreshAnnouncements(progressBlock progressBlock: ((Int) -> ())? = nil, completion: ((ErrorType?) -> ())? = nil ) {
        
        CMSSyncManager.isWorking = true
        
        var announcementsDeleted = false
        
        let dayComponents: NSCalendarUnit = [.Month, .Day, .Year]
        let today = NSDate().dateRetainingComponents(unitFlags: dayComponents)
        
        let query = CKQuery(recordType: "Announcements", predicate: NSPredicate(format: "EndDate >= %@", today))
        
        let queryOperation = CKQueryOperation(query: query)
        
        var count = 0
        
        queryOperation.recordFetchedBlock = { announcement in
            
            var `return` = false
            dispatch_sync(dispatch_get_main_queue()) {
                count += 1
                progressBlock?(count)
                
                if !announcementsDeleted {
                    do {
                        try CMSAnnouncementContext.deleteAll()
                    } catch { NSLog(error.errorDetails); `return` = true }
                    announcementsDeleted = true
                }
                
                if `return` { return }
                
                self.announcementCreated(announcement)
            }
            
        }
        
        queryOperation.queryCompletionBlock = { cursor, error in
            
            if let queryError = error {
                self.handleErrors(queryError) {
                    self.refreshAnnouncements(progressBlock: progressBlock, completion: completion)
                }
            } else { self.resetRetry() }
            
            CMSSyncManager.isWorking = false
            
            completion?(error)
            
        }
        
        publicDatabase.addOperation(queryOperation)
        
        ScheduledClosure.scheduleClosureWithTimeInterval(0.5, tolerance: 0.1, repeats: false) { _ in
            if !queryOperation.finished {
                CMSSyncManager.isWorking = false
                completion?(nil)
            }
        }
        
    }
    
    func refreshAttachments(progressBlock progressBlock: ((Int) -> ())? = nil, completion: ((ErrorType?) -> ())? = nil ) {
        
        CMSSyncManager.isWorking = true
        
        // Delete Local Attachments
        var announcements = [CMSAnnouncement]()
        var `return` = false
        let setup = {
            do {
                try CMSAttachmentContext.clean()
                try CMSAttachmentContext.wipe()
            } catch { NSLog(error.errorDetails); `return` = true; return }
            
            do {
                announcements = try CMSAnnouncementContext.fetchAnnouncements()
            } catch { NSLog(error.errorDetails); `return` = true }
        }
        if let current = NSOperationQueue.currentQueue() where current == NSOperationQueue.mainQueue() {
            setup()
        } else {
            dispatch_sync(dispatch_get_main_queue()) {
                setup()
            }
        }
        
        if `return` { return }
        
        for (index, announcement) in announcements.enumerate() {
            
            let recordID = CKRecordID(recordName: announcement.recordID)
            let predicate = NSPredicate(format: "Announcement = %@", recordID)
            
            let query = CKQuery(recordType: "Attachments", predicate: predicate)
            let queryOperation = CKQueryOperation(query: query)
            
            queryOperation.recordFetchedBlock = { attachmentRecord in
                
                dispatch_sync(dispatch_get_main_queue()) {
                    
                    self.attachmentCreated(attachmentRecord)
                    
                    progressBlock?(index + 1)
                    
                }
                
            }
            
            queryOperation.queryCompletionBlock = { _, error in
                
                if let queryError = error {
                    self.handleErrors(queryError) {
                        self.refreshAttachments(progressBlock: progressBlock, completion: completion)
                    }
                } else { self.resetRetry() }
                
                CMSSyncManager.isWorking = false
                
                completion?(error)
                
                NSNotificationCenter.defaultCenter().postNotificationName(CMSAttachmentsRefreshedNotification, object: nil)
                
            }
            
            publicDatabase.addOperation(queryOperation)
            
        }
        
        if announcements.isEmpty {
            CMSSyncManager.isWorking = false; completion?(nil)
        }
        
    }
    
    private func handleErrors(error: ErrorType, retry: (() -> ())? ) {
        
        switch error {
        case CKErrorCode.ServiceUnavailable:
            NSLog("CloudKit Service Unavailable")
            if let retryAfter = (error as NSError).userInfo[CKErrorRetryAfterKey] as? NSTimeInterval {
                ScheduledClosure.scheduleClosureWithTimeInterval(retryAfter, tolerance: 10, repeats: false) { _ in
                    retry?()
                }
                return
            }
        case CKErrorCode.RequestRateLimited:
            print("CloudKit is Busy")
            if let retryAfter = (error as NSError).userInfo[CKErrorRetryAfterKey] as? NSTimeInterval {
                ScheduledClosure.scheduleClosureWithTimeInterval(retryAfter, tolerance: 10, repeats: false) { _ in
                    retry?()
                }
                return
            }
        case CKErrorCode.ChangeTokenExpired:
            print("CloudKit Change Token Expired")
            changeToken = nil
            ScheduledClosure.scheduleClosureWithTimeInterval(0.5, tolerance: 10, repeats: false) { _ in
                retry?()
            }
            return
        case CKErrorCode.ZoneBusy:
            print("CloudKit Default Zone Busy")
            retryIn = retryIn <= 1 ? retryIn + 1 : pow(retryIn, 2)
            ScheduledClosure.scheduleClosureWithTimeInterval(retryIn, tolerance: 10, repeats: false) { _ in
                retry?()
            }
            return
        default: NSLog(error.errorDetails)
            NSNotificationCenter.defaultCenter().postNotificationName(CMSSyncErrorNotification, object: error as NSError)
        }
        
    }
    
    private let changeTokenPath = CMSFileBrain.pathInDocumentsForFileName("Server Change Token")
    
    private var changeToken: CKServerChangeToken? {
        
        get {
            return NSKeyedUnarchiver.unarchiveObjectWithFile(changeTokenPath) as? CKServerChangeToken
        }
        
        set {
            if let newToken = newValue {
                NSKeyedArchiver.archiveRootObject(newToken, toFile: changeTokenPath)
            } else {
                do {
                    let fileManager = NSFileManager.defaultManager()
                    if fileManager.fileExistsAtPath(changeTokenPath) {
                        try fileManager.removeItemAtPath(changeTokenPath)
                    }
                } catch { NSLog("There was a problem removing the change token: \(error)") }
            }
        }
        
    }
    
    func resetRetry() {
        retryIn = 1
    }

    static func handleSubscriptionError(error: ErrorType, retry: () -> Void) {
        NSLog("Problem saving resource subscription: \(error)")
        
        func tryAgain() {
            ScheduledClosure.scheduleClosureWithTimeInterval(1, repeats: false) { _ in
                retry()
            }
        }
        
        switch error {
        case CKErrorCode.ServiceUnavailable:
            tryAgain()
        case CKErrorCode.RequestRateLimited:
            tryAgain()
        case CKErrorCode.ZoneBusy:
            tryAgain()
        default:
            return
        }
    }
    
    static func subscribeToResources() {
        
        let predicate = NSPredicate(value: true)
        
        let subscription = CKSubscription(recordType: "Resources", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldBadge = false
        notificationInfo.soundName = nil
        notificationInfo.shouldSendContentAvailable = false
        
        subscription.notificationInfo = notificationInfo
        
        CMSSyncManager.defaultContainer.publicCloudDatabase.saveSubscription(subscription, completionHandler: { _, error in
            if let subscriptionError = error {
                handleSubscriptionError(subscriptionError, retry: {
                    subscribeToResources()
                })
            }
        })
        
    }
    
    // For now, ignores category preferences
    static func subscribeToAnnouncementCreation() {
        
        let beginningOfToday = NSDate().dateRetainingComponents(unitFlags: [.Year, .Month, .Day])
        let endOfToday = NSDate().dateRetainingComponents(unitFlags: [.Year, .Month, .Day]).dateByAddingTimeInterval(86400)
        
        let predicate = NSPredicate(format: "StartDate <= %@ AND EndDate >= %@", endOfToday, beginningOfToday)
        //let categoryPredicate = CMSBrain.cloudPredicateForSelectedAnnouncementCategories()
        //let andPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, categoryPredicate])
        
        let subscription = CKSubscription(recordType: "Announcements", predicate: predicate, subscriptionID: "Announcement Creation", options: .FiresOnRecordCreation)
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldBadge = true
        notificationInfo.soundName = UILocalNotificationDefaultSoundName
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.alertLocalizationArgs = ["Title"]
        notificationInfo.alertLocalizationKey = "New Announcement: %@"
        
        subscription.notificationInfo = notificationInfo
        
        CMSSyncManager.defaultContainer.publicCloudDatabase.saveSubscription(subscription, completionHandler: { _, error in
            if let subscriptionError = error {
                handleSubscriptionError(subscriptionError, retry: {
                    subscribeToAnnouncementCreation()
                })
            }
        })
        
    }
    
//    static func subscribeToOtherAnnouncementCreation() {
//        
//        let removePrevious = CKModifySubscriptionsOperation(subscriptionsToSave: [], subscriptionIDsToDelete: ["Other Created Announcements"])
//        removePrevious.modifySubscriptionsCompletionBlock = { _, _, error in
//            
//            if let subscriptionError = error {
//                NSLog(subscriptionError.errorDetails)
//                
//                handleSubscriptionError(subscriptionError, retry: {
//                    subscribeToAnnouncementCreation()
//                })
//                return
//            }
//            
//            let today = NSDate().dateRetainingComponents(unitFlags: [.Year, .Month, .Day])
//            
//            let predicate = NSPredicate(format: "StartDate <= %@ AND EndDate >= %@", NSDate().dateByAddingTimeInterval(1), today)
//            let categoryPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: CMSBrain.cloudPredicateForSelectedAnnouncementCategories())
//            let andPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, categoryPredicate])
//            
//            let subscription = CKSubscription(recordType: "Announcements", predicate: andPredicate, subscriptionID: "Other Created Announcements", options: .FiresOnRecordCreation)
//            
//            let notificationInfo = CKNotificationInfo()
//            notificationInfo.shouldBadge = false
//            notificationInfo.soundName = nil
//            notificationInfo.shouldSendContentAvailable = false
//            
//            subscription.notificationInfo = notificationInfo
//            
//            CMSSyncManager.defaultContainer.publicCloudDatabase.saveSubscription(subscription, completionHandler: { _, error in
//                if let subscriptionError = error {
//                    handleSubscriptionError(subscriptionError, retry: {
//                        subscribeToAnnouncementCreation()
//                    })
//                }
//            })
//            
//        }
//        
//        CMSSyncManager.defaultContainer.publicCloudDatabase.addOperation(removePrevious)
//        
//    }
    
    // For now, ignores category preferences
    static func subscribeToAnnouncementChanges() {
        
        let beginningOfToday = NSDate().dateRetainingComponents(unitFlags: [.Year, .Month, .Day])
        let endOfToday = NSDate().dateRetainingComponents(unitFlags: [.Year, .Month, .Day]).dateByAddingTimeInterval(86400)
        
        let predicate = NSPredicate(format: "StartDate <= %@ AND EndDate >= %@", endOfToday, beginningOfToday)
        //let categoryPredicate = CMSBrain.cloudPredicateForSelectedAnnouncementCategories()
        //let andPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, categoryPredicate])
        
        let subscription = CKSubscription(recordType: "Announcements", predicate: predicate, subscriptionID: "Announcement Edits", options: .FiresOnRecordUpdate)
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldBadge = true
        notificationInfo.soundName = UILocalNotificationDefaultSoundName
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.alertLocalizationArgs = ["Title"]
        notificationInfo.alertLocalizationKey = "Announcement Updated: %@"
        
        subscription.notificationInfo = notificationInfo
        
        CMSSyncManager.defaultContainer.publicCloudDatabase.saveSubscription(subscription, completionHandler: { _, error in
            if let subscriptionError = error {
                handleSubscriptionError(subscriptionError, retry: {
                    subscribeToAnnouncementChanges()
                })
                return
            }
        })
        
    }
    
//    static func subscribeToOtherAnnouncementChanges() {
//        
//        let removePrevious = CKModifySubscriptionsOperation(subscriptionsToSave: [], subscriptionIDsToDelete: ["Other Edited Announcements"])
//        removePrevious.modifySubscriptionsCompletionBlock = { _, _, error in
//            
//            if let subscriptionError = error {
//                NSLog(subscriptionError.errorDetails)
//                
//                handleSubscriptionError(subscriptionError, retry: {
//                    subscribeToAnnouncementChanges()
//                })
//                return
//            }
//            
//            let today = NSDate().dateRetainingComponents(unitFlags: [.Year, .Month, .Day])
//            
//            let predicate = NSPredicate(format: "StartDate <= %@ AND EndDate >= %@", NSDate(), today)
//            let categoryPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: CMSBrain.cloudPredicateForSelectedAnnouncementCategories())
//            let andPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, categoryPredicate])
//            
//            let subscription = CKSubscription(recordType: "Announcements", predicate: andPredicate, subscriptionID: "Other Edited Announcements", options: .FiresOnRecordUpdate)
//            
//            let notificationInfo = CKNotificationInfo()
//            notificationInfo.shouldBadge = false
//            notificationInfo.soundName = nil
//            notificationInfo.shouldSendContentAvailable = false
//            
//            subscription.notificationInfo = notificationInfo
//            
//            CMSSyncManager.defaultContainer.publicCloudDatabase.saveSubscription(subscription, completionHandler: { _, error in
//                if let subscriptionError = error {
//                    handleSubscriptionError(subscriptionError, retry: {
//                        subscribeToAnnouncementChanges()
//                    })
//                    return
//                }
//            })
//            
//        }
//        
//        CMSSyncManager.defaultContainer.publicCloudDatabase.addOperation(removePrevious)
//        
//    }
    
    static func subscribeToAnnouncementDeletion() {
        
        let predicate = NSPredicate(value: true)
        
        let subscription = CKSubscription(recordType: "Announcements", predicate: predicate, options: .FiresOnRecordDeletion)
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldBadge = false
        notificationInfo.soundName = nil
        notificationInfo.shouldSendContentAvailable = false
        
        subscription.notificationInfo = notificationInfo
        
        CMSSyncManager.defaultContainer.publicCloudDatabase.saveSubscription(subscription, completionHandler: { _, error in
            if let subscriptionError = error {
                handleSubscriptionError(subscriptionError, retry: {
                    subscribeToAnnouncementDeletion()
                })
            }
        })
        
    }
    
    static func subscribeToAttachments() {
        
        let predicate = NSPredicate(value: true)
        
        let subscription = CKSubscription(recordType: "Attachments", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldBadge = false
        notificationInfo.soundName = nil
        notificationInfo.shouldSendContentAvailable = false
        
        subscription.notificationInfo = notificationInfo
        
        CMSSyncManager.defaultContainer.publicCloudDatabase.saveSubscription(subscription, completionHandler: { _, error in
            if let subscriptionError = error {
                handleSubscriptionError(subscriptionError, retry: {
                    subscribeToAttachments()
                })
            }
        })
        
    }
    
}