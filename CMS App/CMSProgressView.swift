//
//  CMSProgressView.swift
//  CMS Now
//
//  Created by App Development on 3/7/16.
//  Copyright © 2016 com.chambersburg. All rights reserved.
//

import UIKit

@IBDesignable
class CMSProgressView: UIView {
    
    var view: UIView!
    
    @IBOutlet private weak var lastUpdatedString: UILabel!
    
    @IBOutlet private weak var progressBar: UIProgressView!
    
    var progress: Float = 0 {
        
        willSet {
            updating = true
        }
        
        didSet {
            print(progress)
            progressBar.setProgress(progress, animated: true)
        }
        
    }
    
    func finishProgress() {
        progress = 1.0
    }
    
    func resetProgress() {
        progressBar.setProgress(0, animated: false)
    }
    
    var updating: Bool = false {
        
        didSet {
            progressBar.hidden = !updating
        }
        
    }
    
    private var date: NSDate? {
        
        didSet {
            switch date {
            case nil:
                if CMSSettingsBrain.valueForKey("never_updated") as! Bool {
                    lastUpdatedString.text = "Not Updated"
                } else {
                    date = (CMSSettingsBrain.valueForKey("last_updated") as! NSDate)
                    refreshLastUpdated()
                }
            default: lastUpdatedString.text = "Updated Just Now"
            }
        }
        
    }
    
    /// Set the last updated date to right now.
    func updateDate() {
        date = NSDate()
        saveDate()
    }
    
    /// Stores the last updated info in user defaults.
    private func saveDate() {
        if let recentDate = date {
            CMSSettingsBrain.setValueForKey("never_updated", value: false)
            CMSSettingsBrain.setValueForKey("last_updated", value: recentDate)
        }
    }
    
    /// Update text of last updated label to more accurately reflect the time since a previous update.
    func refreshLastUpdated() {
        
        if let lastDate = date {
            let now = NSDate()
            let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
            let importantUnits: NSCalendarUnit = [.Year, .Month, .Day, .Hour, .Minute, .Second]
            let differenceComponents = calendar.components(importantUnits, fromDate: lastDate, toDate: now, options: .WrapComponents)
            
            /// Describes the verbage of the last updated string.
            enum UpdateWording {
                /// Display a numerical description of a number of units in time.
                case Numerical(unit: String, num: Int)
                /// Use the phrase "a few" to leave the exact number of units ambiguous.
                case Ambiguous(unit: String)
            }
            
            var updateWording: UpdateWording
            if differenceComponents.year >= 1 {
                updateWording = .Numerical(unit: "Year", num: differenceComponents.year)
            } else if differenceComponents.month >= 1 {
                updateWording = .Numerical(unit: "Month", num: differenceComponents.month)
            } else if differenceComponents.day >= 1 {
                updateWording = .Numerical(unit: "Day", num: differenceComponents.day)
            } else if differenceComponents.hour >= 1 {
                updateWording = .Numerical(unit: "Hour", num: differenceComponents.hour)
            } else if differenceComponents.minute >= 1 {
                updateWording = .Numerical(unit: "Minute", num: differenceComponents.minute)
            } else if differenceComponents.second >= 10 {
                updateWording = .Ambiguous(unit: "Second")
            } else {
                lastUpdatedString.text = "Updated Just Now"
                return
            }
            
            switch updateWording {
            case .Numerical(let unit, let quantity):
                lastUpdatedString.text = "Updated \(quantity) \(unit)\(quantity > 1 ? "s" : "") Ago"
            case .Ambiguous(let unit):
                lastUpdatedString.text = "Updated A Few \(unit)s Ago"
            }
            
        } else { lastUpdatedString.text = "Not Updated" }
        
    }
    
    // MARK: - Timer
    
    private var timer: NSTimer!
    
    private func createTimer() {
        timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(CMSProgressView.refreshLastUpdated), userInfo: nil, repeats: true)
    }
    
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
        setup()
    }
    
    private func xibSetup() {
        
        view = loadViewFromNib()
        
        view.frame = bounds
        
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        
        addSubview(view)
        
    }
    
    private func setup() {
        progressBar.hidden = true
        date = nil
        createTimer()
    }

    private func loadViewFromNib() -> UIView {
        
        let nib = UINib(nibName: "CMSProgressView", bundle: NSBundle.mainBundle())
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
    
    deinit {
        timer.invalidate()
    }

}
