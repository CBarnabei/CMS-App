//
//  DetailViewController.swift
//  CMS App
//
//  Created by Magnet Library on 8/21/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!

    var popoverNavigationController: UINavigationController?
    
    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            if let label = self.detailDescriptionLabel {
                label.text = detail.valueForKey("timeStamp")!.description
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ResourceSegue" {
            print("segue")
            popoverNavigationController = segue.destinationViewController as? UINavigationController
            if traitCollection.horizontalSizeClass == .Compact {
                print("compact")
                popoverNavigationController?.navigationBarHidden = false
            } else if traitCollection.horizontalSizeClass == .Regular {
                print("regular")
                popoverNavigationController?.navigationBarHidden = true
            }
        }
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        print("trait collection changed")
        switch traitCollection.horizontalSizeClass {
        case .Compact: popoverNavigationController?.navigationBarHidden = false
        case .Regular: popoverNavigationController?.navigationBarHidden = true
        case .Unspecified: popoverNavigationController?.navigationBarHidden = false
        }
    }
    
}