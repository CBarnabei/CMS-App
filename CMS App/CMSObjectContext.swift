//
//  CMSObjectContext.swift
//  CMS App
//
//  Created by App Development on 10/1/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import Foundation
import CoreData

extension String {
    
    /// Ensure a String value is valid for assigning to an attribute of an NSManagedObject. A String is valid if it contains at least one character.
    func isValidAttributeValue() -> Bool {
        return self.characters.count >= 1
    }
    
}

/// The CMSObjectContext is used as a base class for various object contexts and provides default functionality. Context are objects that are used to access and modify NSManagedObjects in Core Data.
class CMSObjectContext {
    
    /**
    Delete an object from storage.
    - parameter object: The object you want to delete.
    
    **Throws**:
    
    - `CMSCoreDataError.SaveRequestFailed(errorMessage)`: Propagated from `CMSCoreDataBrain.deleteItem` or `CMSCoreDataBrain.saveContext`, originating from `AppDelegate`'s `saveContext()`, which causes the context to rollback upon failure.
    */
    static func delete(object: NSManagedObject) throws {
        do {
            try CMSCoreDataBrain.deleteItem(object)
        } catch { throw error }
    }
    
    /**
    Saves the application's managed object context.
    
    **Throws**:
    
    - `CMSCoreDataError.SaveRequestFailed(errorMessage)`: Propagated from `CMSCoreDataBrain.saveContext`, originating from `AppDelegate`'s `saveContext()`, which causes the context to rollback upon failure.
    */
    static func save() throws {
        do {
            try CMSCoreDataBrain.saveContext()
        } catch { throw error }
    }
    
}