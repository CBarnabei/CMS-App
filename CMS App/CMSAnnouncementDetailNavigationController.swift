//
//  CMSAnnouncementDetailNavigationController.swift
//  CMS Now
//
//  Created by App Development on 2/24/16.
//  Copyright © 2016 com.chambersburg. All rights reserved.
//

import UIKit

class CMSAnnouncementDetailNavigationController: UINavigationController {
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        updateBarColor()
        
        NSNotificationCenter.defaultCenter().addObserverForName(CMSThemeChangedNotification, object: nil, queue: nil) { _ in
            self.updateBarColor()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func updateBarColor() {
        self.navigationBar.tintColor = appColorProfile.light
        self.navigationBar.titleTextAttributes?[NSForegroundColorAttributeName] = appColorProfile.dark
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
