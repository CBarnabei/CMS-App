//
//  CMSAnnouncementSplitViewController.swift
//  Temp CMS Now
//
//  Created by Matthew Benjamin on 2/2/16.
//  Copyright © 2016 CMS. All rights reserved.
//

import UIKit

class CMSAnnouncementSplitViewController: UISplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        self.delegate = appDelegate
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
