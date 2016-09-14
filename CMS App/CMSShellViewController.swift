//
//  CMSShellViewController.swift
//  CMS Now
//
//  Created by App Development on 12/14/15.
//  Copyright © 2015 com.chambersburg. All rights reserved.
//

import UIKit

class CMSShellViewController: UIViewController {
    
    @IBOutlet weak var bar: UINavigationBar!
    
    override func viewDidLoad() {
        bar.barTintColor = appColorProfile.light
        bar.tintColor = UIColor.whiteColor()
        
        NSNotificationCenter.defaultCenter().addObserverForName(CMSThemeChangedNotification, object: nil, queue: nil) { _ in
            self.bar.barTintColor = appColorProfile.light
        }
        
        for parent in bar.subviews {
            for childView in parent.subviews {
                if(childView is UIImageView) {
                    childView.removeFromSuperview()
                }
            }
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if let size = previousTraitCollection?.horizontalSizeClass {
            if let popoverNav = presentedViewController as! UINavigationController? {
                popoverNav.navigationBarHidden = size == .Compact
            }
        }
        
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
