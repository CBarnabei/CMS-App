//
//  ErrorBrain.swift
//  CMS App
//
//  Created by App Development on 9/23/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import Foundation

// Define errors that may need to be dealt with by custom context classes
enum CMSCoreDataError: ErrorType {
    case SaveRequestFailed(String)
    case FetchRequestFailed(String)
    case InvalidObject
}

extension ErrorType {
    
    var errorDetails: String {
        let nserror = self as NSError
        return "\(nserror), \(nserror.userInfo)"
    }
    
}