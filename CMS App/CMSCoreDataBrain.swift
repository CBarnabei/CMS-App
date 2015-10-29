//
//  CMSCoreDataBrain.swift
//  CMS App
//
//  Created by App Development on 10/13/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import Foundation
import CoreData
import UIKit

/// CMSCoreDataBrain handles generic Core Data operations for creating, managing, deleting, and fetching Core Data objects.
class CMSCoreDataBrain {
    
    /// Allows access to the application's Managed Object Context
    static let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    /// An array of all entityNames for Core Data in the application's object graph.
    static let entityNames = ["CMSResource", "CMSAnnouncement", "CMSAttachment"]
    
    /**
    Create item that can be modified and then saved by a context object.
    - Warning: You are responsible for ensuring all parameters required by CoreData are specified for the object before the context is saved. Passing `true` for `saveOnCompletion` will fail if certain attributes are required.
    - Parameter entityName: A `String` representing the entity for the new obect to be created in.
    - Parameter saveOnCompletion: A Bool indicating whether to save the applications managed object context before return. The default value is `false`.
    - Returns: A newly created object without set perameters in specified entity.
    
    **Throws**:
    
    - `CMSCoreDataError.SaveRequestFailed(errorMessage)`: Propagated from `CMSCoreDataBrain.saveContext()`, originating from `AppDelegate`'s `saveContext()`, which causes the context to rollback upon failure.
    */
    static func createCustomizableItemForEntity(entityName: String, saveOnCompletion: Bool = false) throws -> NSManagedObject {
        let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context)!
        let item = NSManagedObject(entity: entity, insertIntoManagedObjectContext: context)
        
        if saveOnCompletion {
            do {
                try saveContext()
            } catch { throw error }
        }
        
        return item
    }
    
    /**
    Return items from an entity that match the key/value pairs. This is done by first creating a predicate and then calling `itemsForPredicate`.
    - Warning: You are responsible for ensuring keys represent valid properties for your object and values are of appropriate type. Has not been tested with values that are not of type String.
    - Parameter keyValuePairs: A dictionary of String and AnyObject representing object properties and values for filtering the search.
    - Parameter forEntityName: A String representing the entity for the new obect to be created in.
    - Returns: An Array of objects matching search query as [NSManagedObject].
    
    **Throws**:
    
    - `CMSCoreDataError.FetchRequestFailed(errorMessage: String)`: Propagated from `CMSCoreDataBrain.itemsForPredicate`
    */
    static func itemsForKeyValuePairs(keyValuePairs: [String : AnyObject], forEntityName entityName: String) throws -> [NSManagedObject] {
        
        // If dict was passed, create search predicate
        var compoundPredicate: NSCompoundPredicate?
        var predicateArray = [NSPredicate]()
        for (key, value) in keyValuePairs {
            let predicate = NSPredicate(format: "\(key) == %@", argumentArray: [value])
            predicateArray.append(predicate)
        }
        compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicateArray)
        
        do {
            return try itemsForPredicate(compoundPredicate, forEntityName: entityName)
        } catch { throw error }
        
    }
    
    /**
    Return items from specified entity for specified search predicate to filter results.
    - Warning: You are responsible for ensuring predicate is formatted correctly.
    - Parameter predicate: An optional NSPredicate for filtering search results.
    - Parameter forEntityName: A String representing the entity for the new obect to be created in.
    - Returns: An Array of objects matching search query as `[NSManagedObject]`.
    
    **Throws**:
    
    - `CMSCoreDataError.FetchRequestFailed(errorMessage: String)`
    */
    static func itemsForPredicate(predicate: NSPredicate?, forEntityName entityName: String) throws -> [NSManagedObject] {
        
        // Create request in entity
        let request = NSFetchRequest(entityName: entityName)
        request.returnsObjectsAsFaults = false
        
        // Set predicate on fetch request
        request.predicate = predicate
        
        // Execute fetch request or throw error
        do {
            let results = try context.executeFetchRequest(request)
            return results as! [NSManagedObject]
        } catch {
            let errorMessage = error.errorDetails
            NSLog(errorMessage)
            throw CMSCoreDataError.FetchRequestFailed(errorMessage: errorMessage)
        }
        
    }
    
    /**
    Return NSManagedObject for object that may not be managed and attached to the store.
    - Parameter object: The managed object you want to receive a valid managed object for.
    - Parameter forEntityName: A String representing the entity for the new obect to be created in.
    - Returns: An `NSManagedObject` identical to the copycat. The definition of identical depends on the type of the passed object.
    
    **Throws**:
    
    - `CMSCoreDataError.InvalidObject`: The type of copycat is not supported by the CoreData structure.
    
    
    - `CMSCoreDataError.FetchRequestFailed(errorMessage: String)`: Something was wrong with the properties of the passed copycat: Propagated from `CMSCoreDataBrain.itemsForKeyValuePairs`, Originating from `CMSCoreDataBrain.itemsForPredicate`
    */
    static func itemInStorageForObject(object: NSManagedObject, forEntityName entityName: String) throws -> NSManagedObject {
        var keyValuePairs = [String : AnyObject]()
        if object is CMSResource {
            let resource = object as! CMSResource
            let label = resource.label!
            keyValuePairs = ["label": label]
        } else if object is CMSAnnouncement {
            let announcememt = object as! CMSAnnouncement
            let title = announcememt.title!
            let dates = announcememt.dates!
            keyValuePairs = ["title": title, "dates": dates]
        } else if object is CMSAttachment {
            let attachment = object as! CMSAttachment
            let title = attachment.title!
            let type = attachment.type!
            let filePath = attachment.filePath!
            keyValuePairs = ["title": title, "type": type, "filePath": filePath]
        } else if object is CMSDate {
            let date = object as! CMSDate
            let nsdate = date.date!
            keyValuePairs = ["date": nsdate]
        } else {
            throw CMSCoreDataError.InvalidObject(object: object)
        }
        do {
            return try itemsForKeyValuePairs(keyValuePairs, forEntityName: entityName)[0]
        } catch { throw error }
    }
    
    /**
    Delete item from persistent store.
    - Parameter item: the `NSManagedObject` that you would like to delete.
    - Parameter saveOnCompletion: A Bool indicating whether to save the application's managed object context before return. The default value is true.
    
    **Throws**:
    
    - `CMSCoreDataError.SaveRequestFailed(errorMessage: String)`: Propagated from `CMSCoreDataBrain.saveContext`: Originating from `AppDelegate.saveContext`, which causes the context to rollback upon failure.
    */
    static func deleteItem(item: NSManagedObject, saveOnCompletion: Bool = true) throws {
        context.deleteObject(item)
        if saveOnCompletion {
            do {
                try saveContext()
            } catch { throw error }
        }
    }
    
    /**
    Delete everything from a specified entity without needing to fetch the objects first.
    - Parameter entityName: The entity name that you want to delete everything from.
    - Parameter saveOnCompletion: A Bool indicating whether to save the application's managed object context before return. The default value is true.
    
    Throws:
    
    - `CMSCoreDataError.SaveRequestFailed(errorMessage: String)`: Propagated from `CMSCoreDataBrain.deleteItem`: Originating from `AppDelegate.saveContext`
    
    
    - `CMSCoreDataError.BatchDeleteRequestFailed(errorMessage: String)`: The context will rollback first.
    */
    static func deleteAllForEntity(entityName: String, saveOnCompletion: Bool = true) throws {
        do {
            let fetchRequest = NSFetchRequest(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.executeRequest(deleteRequest)
        } catch {
            context.rollback()
            throw CMSCoreDataError.BatchDeleteRequestFailed(errorMessage: error.errorDetails)
        }
        do {
            if saveOnCompletion { try saveContext() }
        } catch { throw error }
    }
    
    /**
    Delete everything from the persistent store without fetching objects first.
    - Parameter saveOnCompletion: A Bool indicating whether to save the applications managed object context before return. The default value is true.
    
    **Throws**:
    
    - `CMSCoreDataError.SaveRequestFailed(errorMessage: String)`: Propagated from `CMSCoreDataBrain.deleteAllForEntity`: Originating from `AppDelegatge.saveContext`, which causes the context to rollback upon failure.
    */
    static func deleteEverything(saveOnCompletion saveOnCompletion: Bool = true) throws {
        do {
            for entity in entityNames {
                try deleteAllForEntity(entity, saveOnCompletion: false)
            }
            if saveOnCompletion { try saveContext() }
        } catch { throw error }
    }
    
    /**
    Save the application's Managed Object Context on the persistent store.
    
    **Throws**:
    
    - CMSCoreDataError.SaveRequestFailed(errorString): Propagated from `AppDelegate.saveContext`, which causes the context to rollback upon failure.
    */
    static func saveContext() throws {
        do {
            try (UIApplication.sharedApplication().delegate as! AppDelegate).saveContext()
        } catch { throw error }
    }
    
}