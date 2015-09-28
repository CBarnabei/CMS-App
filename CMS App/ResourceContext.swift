//
//  ResourceBrain.swift
//  CMS App
//
//  Created by Magnet Library on 8/28/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import Foundation

// Provides access to Recources from Core Data
class CMSRecourceContext {
    
    static let resourceEntityName = "CMSResource"
    
    static func addResource(label: String, urlString: String) -> CMSResource? {
        assert(NSURL(string: urlString) != nil, "The URL for \(label) is not valid.")
        do {
            let resource = try CMSCoreDataBrain.createCustomizableItemForEntity(resourceEntityName) as! CMSResource
            resource.label = label
            resource.url = urlString
            try CMSCoreDataBrain.saveContext()
            return resource
        } catch {
            let errorString = error.errorDetails
            NSLog(errorString)
            return nil
        }
    }
    
}

/*
/**
A package to represent a bundle of all resources. Resources are links to useful sites and labels representing what should be displayed in the Resources menu.

New resources must be added within the initializer declaration in the ResourceBrain.swift file.
*/
class ResourcePackage {
    
    /// A Resource is really just a tuple containing a String, to be displayed in the user-readable menu, and an NSURL representing the website addess.
    typealias Resource = (label: String, URL: NSURL)
    
    /// The collection of all resources in a resource package. A Resource is really just a tuple containing a String, to be displayed in the user-readable menu, and an NSURL representing the website addess.
    var resources = [Resource]()
    
    /**
    Add new resources to the resources array of a resource package.
    - Parameter label: A String representing the **short** label that the user should see.
    - Parameter URLString: A String representing an exact and complete URL for the web resource.
    - Warning: An assertion will be thrown if the URLString does not appear to be a valid URL.
    */
    private func addResource(label: String, URLString: String) {
        let URL = NSURL(string: URLString)
        assert(URL != nil, "The URL for \(label) is not valid.")
        let resource = (label, URL!)
        resources.append(resource)
    }
    
    // resources can only be added from the initializer so that they may only be changed within the definition of a resource package
    init() {
        addResource("HomeLogic", URLString: "https://logic.chambersburg.k12.pa.us/homelogic/")
        addResource("Tech Handbook", URLString: "http://chambersburg.libguides.com/content.php?pid=479993&sid=3933158")
        addResource("Library Resources", URLString: "http://chambersburg.libguides.com/content.php?pid=479993&sid=3933172")
        addResource("CMS Homepage", URLString: "http://www.casdonline.org/education/school/school.php?sectionid=2591&")
        addResource("CASD Homepage", URLString: "http://www.casdonline.org/education/components/scrapbook/default.php?sectiondetailid=29880&")
        addResource("CMStival", URLString: "http://cmstival.jimdo.com")
    }
    
}
*/