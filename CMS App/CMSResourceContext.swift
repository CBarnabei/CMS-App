//
//  ResourceBrain.swift
//  CMS App
//
//  Created by Magnet Library on 8/28/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import CloudKit

struct CMSMockResource {
    let label: String
    let url: NSURL
}

/// Provides access to Recources from Core Data
class CMSResourceContext {
    
    private static let entityName = "CMSResource"
    
    static func fetchAll() throws -> [CMSResource] {
        do {
            return try CMSCoreDataBrain.itemsForPredicate(nil, forEntityName: entityName) as! [CMSResource]
        } catch { throw error }
    }
    
    static func mockResources() throws -> [CMSMockResource] {
        
        do {
            let resources = try fetchAll()
            let mockResources = resources.map {
                resource -> CMSMockResource in
                let label = resource.label!
                let url = NSURL(string: resource.urlString!)!
                return CMSMockResource(label: label, url: url)
            }
            return mockResources.sort { $0.label < $1.label }
        } catch { throw error }
        
    }
    
    private static func addResource(label: String, urlString: String, recordIDName: String) throws -> CMSResource {
        
        // Validate Strings
        guard !label.isEmpty else { throw CMSResourceError.EmptyLabel }
        guard NSURL(string: urlString) != nil else { throw CMSResourceError.InvalidURL(passedURL: urlString) }
        
        // Duplicate Protection
        let searchPredicate = NSPredicate(format: "label == %@ OR urlString == %@", argumentArray: [label, urlString])
        let duplicates = try CMSCoreDataBrain.itemsForPredicate(searchPredicate, forEntityName: entityName)
        guard duplicates.isEmpty else { throw CMSResourceError.DuplicateResource }
        
        // Create Resource
        let resource = try CMSCoreDataBrain.createCustomizableItemForEntity(entityName) as! CMSResource
        resource.label = label
        resource.urlString = urlString
        resource.recordID = recordIDName
        try CMSCoreDataBrain.saveContext()
        return resource
    }
    
    private static func deleteResource(resource: CMSResource) {
        try! CMSCoreDataBrain.deleteItem(resource)
    }
    
    static func deleteAll() throws {
        
        try CMSCoreDataBrain.deleteAllForEntity("CMSResource")
        
    }
    
    
    // MARK: - iCloud Support
    
    static func addResource(record: CKRecord) throws {
        
        // Make sure the record represents a resource.
        guard record.recordType == "Resources" else { throw CMSCloudError.RecordOfWrongType }
        
        // Get values from record
        let label = record["Label"] as! String
        let urlString = record["URL"] as! String
        
        // Create resource
        try addResource(label, urlString: urlString, recordIDName: record.recordID.recordName)
        
    }
    
    static func resourceForRecordID(recordID: CKRecordID) throws -> CMSResource? {
        let predicate = NSPredicate(format: "recordID == %@", argumentArray: [recordID.recordName])
        let resources = try CMSCoreDataBrain.itemsForPredicate(predicate, forEntityName: "CMSResource")
        return resources.isEmpty ? nil : (resources[0] as! CMSResource)
    }
    
    private static func changeValue(forRecordID recordID: CKRecordID, changeValue: (CMSResource) -> () ) throws {
        
        let resource: CMSResource! = try resourceForRecordID(recordID)
        
        guard resource != nil else { throw CMSResourceError.IDNotFound }
        
        changeValue(resource)
        
        try CMSCoreDataBrain.saveContext()
        
    }
    
    static func changeLabel(newLabel: String, forRecordID recordID: CKRecordID) throws {
        try changeValue(forRecordID: recordID) { resource in
            resource.label = newLabel
        }
    }
    
    static func changeURL(newUrlString: String, forRecordID recordID: CKRecordID) throws {
        try changeValue(forRecordID: recordID) { resource in
            resource.urlString = newUrlString
        }
    }
    
    static func deleteResource(recordID: CKRecordID) throws {
        
        let resource = try resourceForRecordID(recordID)
        
        if let resourceToDelete = resource {
            deleteResource(resourceToDelete)
        } else { throw CMSResourceError.IDNotFound }
        
    }
    
}