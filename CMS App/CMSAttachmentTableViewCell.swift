//
//  CMSAttachmentTableViewCell.swift
//  Temp CMS Now
//
//  Created by Matthew Benjamin on 2/2/16.
//  Copyright © 2016 CMS. All rights reserved.
//

import UIKit

class CMSAttachmentTableViewCell: UITableViewCell {
    
    @IBOutlet weak var icon: UIImageView!
    
    @IBOutlet weak var title: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
