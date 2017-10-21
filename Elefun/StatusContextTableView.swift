//
//  StatusContextTableView.swift
//  Elefun
//
//  Created by Calv Collins on 02/08/2017.
//  Copyright © 2017 Calv Collins. All rights reserved.
//

import UIKit
import MastodonKit

class StatusContextTableView: UITableView, UITableViewDelegate, UITableViewDataSource {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    var statuses: [Status] = []
    
    func initialiseSelf() {
        self.rowHeight = 75
        self.dataSource = self
        self.delegate = self
    }
    
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        initialiseSelf()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialiseSelf()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return statuses.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: StatusViewController.CELL_NAME, for: indexPath) as? NotificationTableViewCell else {
            print("cell isn't a status view cell")
            return tableView.dequeueReusableCell(withIdentifier: StatusViewController.CELL_NAME, for: indexPath)
        }
        
        var status = statuses[indexPath.row]
        cell.index = indexPath.row
        
        if status.reblog != nil {
            Helper.DownloadImageToView(url: status.account.avatar, view: cell.relatedAvatarView)
            cell.relatedAvatarView.isHidden = false
            cell.typeView.image = UIImage(named: "reblog")
            cell.typeView.isHidden = false
            
            status = status.reblog!
        } else {
            cell.relatedAvatarView.isHidden = true
            cell.typeView.isHidden = true
        }
        
        if status.account.displayName.isEmpty {
            cell.userLabel.text = status.account.acct // use username if displayname is empty
        } else {
            cell.userLabel.text = status.account.displayName
        }
        
        cell.statusLabel.text = Helper.ExtractContent(content: Helper.EscapeString(string: status.content))
        
        Helper.DownloadImageToView(url: status.account.avatar, view: cell.avatarView!)

        cell.setNeedsDisplay()
        
        return cell
    }
    
    func onCellPress(sender: Any?) {
        StatusViewController().performSegue(withIdentifier: "replySelect", sender: sender)
    }

    
    func makeGray() {
        self.superview!.backgroundColor = Helper.lightGray
        self.backgroundColor = Helper.lightGray
        for view in self.subviews {
            view.backgroundColor = Helper.lightGray
        }
    }

}
