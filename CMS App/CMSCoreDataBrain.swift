//
//  CMSCoreDataBrain.swift
//  CMS App
//
//  Created by App Development on 9/24/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import Foundation
import CoreData
import UIKit

// Class that handles generic Core Data operations
class CMSCoreDataBrain {
    
    // Store the application's Managed Object Context for the brain's use
    static let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    // Store the application's entityNames
    static let entityNames = ["CMSResource"]
    
    // Create item without saving that can be modified and then saved by a context
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
    
    // Return items that match key/value pair
    static func itemsForKeyValuePairs(keyValuePairs: [String : AnyObject]?, forEntityName: String) throws -> [NSManagedObject] {
        
        // If dict was passed, create search predicate
        var compoundPredicate: NSCompoundPredicate?
        if let keyValuePairsDict = keyValuePairs {
            var predicateArray = [NSPredicate]()
            for (key, value) in keyValuePairsDict {
                let predicate = NSPredicate(format: "\(key) == %@", argumentArray: [value])
                predicateArray.append(predicate)
            }
            compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicateArray)
        }
        
        do {
            return try itemsForPredicate(compoundPredicate, forEntityName: forEntityName)
        } catch { throw error }
        
    }
    
    // Return items matching search predicate
    static func itemsForPredicate(predicate: NSPredicate?, forEntityName: String) throws -> [NSManagedObject] {
        
        // Create request in entity
        let request = NSFetchRequest(entityName: forEntityName)
        request.returnsObjectsAsFaults = false
        
        // Set predicate on fetch request
        request.predicate = predicate
        
        // Execute fetch request or throw error
        do {
            let results = try context.executeFetchRequest(request)
            return results as! [NSManagedObject]
        } catch {
            let errorString = error.errorDetails
            NSLog(errorString)
            throw CMSCoreDataError.FetchRequestFailed(errorMessage: errorString)
        }
        
    }
    
    // Return ManagedObject for object that may not be attached to the store
    static func itemInStorageForObject(object: NSManagedObject, forEntityName: String) throws -> NSManagedObject {
        var keyValuePairs = [String : AnyObject]()
        if object is CMSResource {
            let resource = object as! CMSResource
            let label = resource.label!
            keyValuePairs = ["label" : label]
        } else {
            NSLog("Invalid object sent to itemForCopycat() in CMSCoreDataBrain.")
            throw CMSCoreDataError.InvalidObject(object: object)
        }
        do {
            return try itemsForKeyValuePairs(keyValuePairs, forEntityName: forEntityName)[0]
        } catch { throw error }
    }
    
    // Delete passed item
    static func deleteItem(item: NSManagedObject, saveOnCompletion: Bool = true) throws {
        context.deleteObject(item)
        if saveOnCompletion {
            do {
                try saveContext()
            } catch { throw error }
        }
    }
    
    /// Delete everything in entity
    static func deleteAllForEntity(entityName: String, saveOnCompletion: Bool = true) throws {
        do {
            let fetchRequest = NSFetchRequest(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.executeRequest(deleteRequest)
            if saveOnCompletion {
                try saveContext()
            }
        } catch CMSCoreDataError.BatchDeleteRequestFailed(let errorMessage) {
            context.rollback()
            throw CMSCoreDataError.BatchDeleteRequestFailed(errorMessage: errorMessage)
        } catch { throw error }
    }
    
    /// Delete everything in all entities
    static func deleteEverything(saveOnCompletion: Bool = true) throws {
        do {
            for entityName in entityNames {
                try deleteAllForEntity(entityName)
            }
            if saveOnCompletion {
                try saveContext()
            }
        } catch { throw error }
    }
    
    // Save Managed Object Context
    static func saveContext() throws {
        do {
            try (UIApplication.sharedApplication().delegate as! AppDelegate).saveContext()
        } catch { throw error }
    }
    
}