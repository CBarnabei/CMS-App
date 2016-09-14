//
//  DetailViewController.swift
//  CMS App
//
//  Created by Magnet Library on 8/21/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import UIKit
import SafariServices

class CMSAnnouncementViewController: UIViewController, UITextViewDelegate, SFSafariViewControllerDelegate {
    
    deinit {
        print("Invalidating Timer")
        timer?.invalidate()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @IBOutlet weak var dateTitle: UINavigationItem!

    @IBOutlet var noSelectionLabel: UILabel!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var categoryLabel: UILabel!
    
    @IBOutlet weak var bodyText: UITextView!
    
    @IBOutlet var titleLine: UIView!
    
    @IBOutlet weak var attachmentBarButton: UIBarButtonItem!

    var popoverNavigationController: UINavigationController?
    
    var titleItem: String? {
        didSet {
            // Update the view
            if let theTitleLabel = titleLabel {
                theTitleLabel.text = titleItem
            }
        }
    }
    
    var categoryItem: String? {
        didSet {
            // Update the view
            if let theCategoryLabel = categoryLabel {
                theCategoryLabel.text = CMSSettingsBrain.categoriesForKeys[categoryItem!]
                updateColors()
            }
        }
    }
    
    var bodyItem: String? {
        didSet {
            // Update the view
            if let theBodyText = bodyText {
                theBodyText.text = bodyItem
            }
        }
    }
    
    var announcement: CMSAnnouncement!
    
    var attachments = [CMSAttachment]() {
        
        willSet {
            resetAttachmentState(newValue.count)
        }
        
    }
    
    func resetAttachmentState(count: Int) {
        attachmentBarButton.enabled = count > 0
    }
    
    func resetAttachmentState() {
        resetAttachmentState(attachments.count)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        dateTitle.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        
        NSNotificationCenter.defaultCenter().addObserverForName(CMSThemeChangedNotification, object: nil, queue: nil) { _ in
            self.updateColors()
        }
        
        resetAttachmentState(attachments.count)
        updateDate()
        updateView()
        bodyText.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CMSAnnouncementViewController.updateDate), name: NSCalendarDayChangedNotification, object: nil)
        
        if attachments.count != 0 { beginTimer() }
        
        registerForNotifications()
    }
    
    func updateView() {
        if titleItem == nil {
            titleLabel!.hidden = true
            categoryLabel!.hidden = true
            bodyText!.hidden = true
            titleLine.hidden = true
            noSelectionLabel.hidden = false
        } else {
            noSelectionLabel.hidden = true
            titleLabel!.hidden = false
            titleLabel.text = titleItem!
            categoryLabel!.hidden = false
            updateColors()
            categoryLabel.text = CMSSettingsBrain.categoriesForKeys[categoryItem!]!
            bodyText!.hidden = false
            bodyText.text = bodyItem!
            titleLine.hidden = false
        }
    }
    
    func updateColors() {
        if let category = categoryItem {
            categoryLabel.textColor = CMSColorProfile.colorForCategoryKey(category)
        }
        bodyText.tintColor = appColorProfile.dark
    }
    
    func updateDate() {
        dateTitle.title = NSDateFormatter().monthDay(NSDate())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "attachmentsSegue" {
            let attachmentsNC = segue.destinationViewController as! UINavigationController
            let attachmentsVC = attachmentsNC.viewControllers.first! as! CMSAttachmentTableViewController
            attachmentsVC.attachments = attachments
        }
    }
    
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        print("boom")
        if URL.scheme == "http" || URL.scheme == "https" {
            let SFVC = SFSafariViewController(URL: URL)
            SFVC.delegate = self
            SFVC.modalPresentationStyle = .PageSheet
            SFVC.modalTransitionStyle = .CoverVertical
            presentViewController(SFVC, animated: true, completion: nil)
            return false
        } else { return true }
    }
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: Notifications
    
    func registerForNotifications() {
        NSNotificationCenter.defaultCenter().addObserverForName(CMSAttachmentsRefreshedNotification, object: nil, queue: nil, usingBlock: { _ in
            if let theAnnouncement = self.announcement, let announcementAttachments = theAnnouncement.attachments {
                self.attachments = announcementAttachments.allObjects as! [CMSAttachment]
            }
        })
    }
    
    
    // MARK: - Button Flashing
    
    var timer: NSTimer? = nil
    
    func beginTimer() {
        print("Creating Timer")
        timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(CMSAnnouncementViewController.flashAttachmentButton), userInfo: nil, repeats: false)
        timer?.tolerance = 3
    }
    
    func flashAttachmentButton() {
        print("Flash Attachment Button")
        UIView.animateWithDuration(0.5, animations: { self.attachmentBarButton.tintColor = UIColor.whiteColor() }, completion: { _ in
            UIView.animateWithDuration(0.20, animations: { self.attachmentBarButton.tintColor = appColorProfile.light }, completion: { _ in
                UIView.animateWithDuration(0.20, animations: { self.attachmentBarButton.tintColor = UIColor.whiteColor() }, completion: { _ in
                    UIView.animateWithDuration(0.20, animations: { self.attachmentBarButton.tintColor = appColorProfile.light })
                })
            })
        })
        timer?.invalidate()
        
    }
    
    
}