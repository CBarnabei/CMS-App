//
//  CategoryTableViewController.swift
//  CMS App
//
//  Created by App Development on 9/14/15.
//  Copyright © 2015 Magnet Library. All rights reserved.
//

import UIKit

class CMSCategoryTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsSelection = false
        
        fetchCategories()
        setBarForPopover()
        sizeTable(rowCount: categories.count)

    }
    
    @IBAction func dismiss(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    let cellID = "categoryCell"
    var categories = [String]()
    var categoryKeys = [String]()
    
    func fetchCategories() {
        let editable = ["Lunch", "Sports", "Clubs", "PTSA", "FCCTC"]
        categories = [String](count: editable.count, repeatedValue: "")
        categoryKeys = [String](count: editable.count, repeatedValue: "")
        for (key, category) in CMSSettingsBrain.categoriesForKeys {
            if let index = editable.indexOf(category) {
                categories[index] = category
                categoryKeys[index] = key
            }
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // There is no need for categories to be grouped into more than one section
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // We should have as many rows as there are categories
        return categories.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellID, forIndexPath: indexPath) as! CMSCategoryTableViewCell

        // Configure the cell...
        cell.categoryTitle.text = categories[indexPath.row]
        cell.toggleSwitch.on = CMSSettingsBrain.valueForKey(categoryKeys[indexPath.row]) as! Bool
        cell.toggleSwitch.tag = indexPath.row
        cell.toggleSwitch.addTarget(self, action: #selector(CMSCategoryTableViewController.switchToggled(_:)), forControlEvents: .ValueChanged)
        
        return cell
    }
    
    func switchToggled(triggeredSwitch: UISwitch) {
        print("\(categories[triggeredSwitch.tag]) category toggled")
        let key = categoryKeys[triggeredSwitch.tag]
        let oldValue = CMSSettingsBrain.valueForKey(key) as! Bool
        CMSSettingsBrain.setValueForKey(key, value: !oldValue)
        //CMSSyncManager.subscribeToAnnouncementCreation()
        //CMSSyncManager.subscribeToOtherAnnouncementCreation()
        //CMSSyncManager.subscribeToAnnouncementChanges()
        //CMSSyncManager.subscribeToOtherAnnouncementChanges()
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
