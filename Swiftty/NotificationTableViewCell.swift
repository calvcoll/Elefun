//
//  NotificationTableViewCell.swift
//  Swiftty
//
//  Created by Calv Collins on 13/08/2017.
//  Copyright © 2017 Calv Collins. All rights reserved.
//

import UIKit

class NotificationTableViewCell: UITableViewCell {

    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var typeView: UIImageView!
    @IBOutlet weak var relatedAvatarView: UIImageView!
    
    var index: Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        userLabel.text = "user"
        statusLabel.text = "status placeholder"
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}
