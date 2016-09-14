//
//  CMSCategoryTableViewCell.swift
//  Temp CMS Now
//
//  Created by Matthew Benjamin on 1/28/16.
//  Copyright © 2016 CMS. All rights reserved.
//

import UIKit

class CMSCategoryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var categoryTitle: UILabel!
    
    @IBOutlet weak var toggleSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
