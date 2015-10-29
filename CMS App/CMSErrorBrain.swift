//
//  ErrorBrain.swift
//  CMS App
//
//  Created by App Development on 9/23/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import Foundation
import CoreData

// Define errors that may need to be dealt with by custom context classes

/**
A family of errors that may occur when reading and writing from Core Data.

Cases:

- SaveRequestFailed(errorMessage: String): The attempt to save the changes failed.


- FetchRequestFailed(errorMessage: String): The attempt to execute the fetch request failed.


- BatchDeleteRequestFailed(errorMessage: String): The attempt to execute the batch delete request failed.


- InvalidObject(object: NSManagedObject): A specified object was not valid for the requirements.
*/
enum CMSCoreDataError: ErrorType {
    
    /// The attempt to save the changes failed. This may happen if something is wrong with the SQL database or if the changes made do not meet the requirements specified in the Core Data object structure.
    case SaveRequestFailed(errorMessage: String)
    
    case FetchRequestFailed(errorMessage: String)
    
    case BatchDeleteRequestFailed(errorMessage: String)
    
    /// A specified object was not valid for the requirements.
    case InvalidObject(object: NSManagedObject)
}


/**
A family of errors relevant to the CMSResource object.

Cases:

- InvalidURL(passedURL: String): The specified URL is not valid.


- EmptyLabel: The passed label for the resource was an empty String.
*/
enum CMSResourceError: ErrorType {
    
    /// The specified URL is not valid. This will happen if NSURL fails to initialize using the passed URL String.
    case InvalidURL(passedURL: String)
    
    /// The passed label for the resource was an empty String. This is not allowed. A resource label must contain at least one character.
    case EmptyLabel
}

/**
A family of errors relevant to the CMSAnnouncement object.

Cases:

- EmptyTitle: The passed title for the announcement was an empty String.


- EmptyBody: The passed formatted text for the announcement an empty String.


- InvalidAttachment(attachment: CMSAttachment): One or more attachments specified could not be found in the SQL database.
*/
enum CMSAnnouncementError: ErrorType {
    
    /// The passed title for the announcement was an empty String. This is not allowed. An announcement title must contain at least one character.
    case EmptyTitle
    
    /// The passed formatted text for the announcement an empty String. This is not allowed. Announcement body text must contain at least one character.
    case EmptyBody
    
    /// One or more attachments specified could not be found in the SQL database. Attachments are validated before talking to Core Data, so no requested data changes or fetches are attemped after a failed validation. The included CMSAttachment represents the first object causing a failed validation.
    case InvalidAttachment(attachment: CMSAttachment)
}

/// An undecalred family of errors for the CMSAttachment object.
enum CMSAttachmentError: ErrorType {}

extension ErrorType {
    
    /// Provides on-demand computed details about a particular error. The error is listed first, followed by a comma and space, followed by the user info dictionary.
    var errorDetails: String {
        let nserror = self as NSError
        return "\(nserror), \(nserror.userInfo)"
    }
    
}