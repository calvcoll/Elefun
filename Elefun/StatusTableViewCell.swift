//
//  StatusTableViewCell.swift
//  Elefun
//
//  Created by Calv Collins on 31/07/2017.
//  Copyright © 2017 Calv Collins. All rights reserved.
//

import UIKit

class StatusTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var avatarView: UIImageView!
    
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
