//
//  CMS_AppTests.swift
//  CMS AppTests
//
//  Created by Magnet Library on 8/21/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import XCTest
@testable import CMS_App

class CMS_AppTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        do {
            try CMSCoreDataBrain.deleteEverything()
        } catch {
            XCTFail("Deleting Everything Failed")
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
    }
    
    func testDriveStorage() {
        do {
            
            let resource = try CMSResourceContext.addResource("HomeLogic", urlString: "https://logic.chambersburg.k12.pa.us/homelogic/")
            XCTAssert(resource.label == "HomeLogic")
            XCTAssert(resource.url == "https://logic.chambersburg.k12.pa.us/homelogic/")
            
            let resources = try CMSResourceContext.fetchAll()
            XCTAssert(resources.count == 1)
            
            try CMSResourceContext.delete(resource)
            
        } catch { XCTFail() }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}