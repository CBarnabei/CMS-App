//
//  CMSAttachmentTableViewController.swift
//  Temp CMS Now
//
//  Created by Matthew Benjamin on 2/2/16.
//  Copyright © 2016 CMS. All rights reserved.
//

import UIKit

class CMSAttachmentTableViewController: UITableViewController, UIDocumentInteractionControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = true
        
        setBarForPopover()
        sizeTable(rowCount: attachments.count, rowHeight: 100)
        
        prepareAttachments()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareAttachments() {
        
        for attachment in attachments {
            let fileURL = CMSFileBrain.urlInDocumentsForFileName("\(CMSAttachmentContext.folderName)/\(attachment.fileName)")
            let documentInteractionController = UIDocumentInteractionController(URL: fileURL)
            documentInteractionController.delegate = self
            documentInteractionController.name = attachment.title
            documentInteractionControllersForAttachments[attachment] = documentInteractionController
        }
        
    }

    // MARK: - Table view data source
    
    let cellID = "attachmentCell"
    
    var attachments = [CMSAttachment]()
    var documentInteractionControllersForAttachments = [CMSAttachment: UIDocumentInteractionController]()

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attachments.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellID, forIndexPath: indexPath) as! CMSAttachmentTableViewCell

        // Configure the cell...
        let attachment = attachments[indexPath.row]
        let documentInteractionController = documentInteractionControllersForAttachments[attachment]!
        
        let iconCount = documentInteractionController.icons.count
        cell.icon.image = documentInteractionController.icons[iconCount >= 4 ? 3 : iconCount - 1]
        
        cell.title.text = documentInteractionController.name
        
        cell.contentView.gestureRecognizers = documentInteractionController.gestureRecognizers

        return cell
    }
    
    
    // MARK: - Document Interaction Controller Delegate
    
    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }

}
