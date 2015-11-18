//
//  ResourceBrain.swift
//  CMS App
//
//  Created by Magnet Library on 8/28/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import Foundation
import CoreData

struct CMSMockResource {
    let label: String
    let url: NSURL
}

// Provides access to Recources from Core Data
class CMSResourceContext {
    
    static let entityName = "CMSResource"
    
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
    
    static func addResource(label: String, urlString: String) throws -> CMSResource {
        
        // Validate Strings
        guard !label.isEmpty else { throw CMSResourceError.EmptyLabel }
        guard NSURL(string: urlString) != nil else { throw CMSResourceError.InvalidURL(passedURL: urlString) }
        
        // Create Resource
        do {
            let resource = try CMSCoreDataBrain.createCustomizableItemForEntity(entityName) as! CMSResource
            resource.label = label
            resource.urlString = urlString
            try CMSCoreDataBrain.saveContext()
            return resource
        } catch { throw error }
    }
    
}

/*
// resources can only be added from the initializer so that they may only be changed within the definition of a resource package
init() {
addResource("HomeLogic", URLString: "https://logic.chambersburg.k12.pa.us/homelogic/")
addResource("Tech Handbook", URLString: "http://chambersburg.libguides.com/content.php?pid=479993&sid=3933158")
addResource("Library Resources", URLString: "http://chambersburg.libguides.com/content.php?pid=479993&sid=3933172")
addResource("CMS Homepage", URLString: "http://www.casdonline.org/education/school/school.php?sectionid=2591&")
addResource("CASD Homepage", URLString: "http://www.casdonline.org/education/components/scrapbook/default.php?sectiondetailid=29880&")
addResource("CMStival", URLString: "http://cmstival.jimdo.com")
}
*/