//
//  MoreViewController.swift
//  Elefun
//
//  Created by Calv Collins on 30/07/2017.
//  Copyright © 2017 Calv Collins. All rights reserved.
//

import UIKit
import MastodonKit

class NotficationViewController: UITableViewController {
    
    enum NotificationError: Error {
        case NotStatus
    }
    
    var client: Client!
    var accessInfo: AccessInfo!
    var notifications: [MastodonKit.Notification] = []
    
    override func awakeFromNib() {
        self.tableView!.rowHeight = 75
        
        self.accessInfo = AccessInfo.loadAccessInfo()!
        self.client = Client(baseURL: accessInfo.url, accessToken: accessInfo.accessToken)
        self.refreshControl = UIRefreshControl()
        
        refreshControl!.backgroundColor = UIColor.white
        refreshControl!.tintColor = UIColor.darkGray
        refreshControl!.addTarget(self, action: #selector(refresh(refreshControl:)), for: UIControlEvents.valueChanged)
        
        getStatuses()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Do any additional setup after loading the view, typically from a nib.
        
        
    }
    
    @objc func refresh(refreshControl: UIRefreshControl) {
        getStatuses()
    }
    
    func getStopIndex(notifications: [MastodonKit.Notification]) -> Int {
        var index = -1
        var i = 0
        
        if self.notifications.count > 0 {
            for notification in notifications {
                if notification.id == self.notifications[0].id {
                    index = i
                }
                i += 1
            }
        } else {
            index = -2
        }
        return index
    }
    
    func getStatuses () {
        client.run(Notifications.all()) { (result) in
            let notifications = result.value
            let error = result.error
            DispatchQueue.main.async {
                if self.refreshControl != nil {
                    self.refreshControl!.endRefreshing()
                }
            }
            if error != nil {
                print(error!)
                return
            }
            if notifications != nil {
                let index = self.getStopIndex(notifications: notifications!)
                if index == -1 {
                    self.notifications = notifications!
                } else if index == 0 {
                } else if index == -2 {
                    let notifications = notifications!
                    self.notifications.insert(contentsOf: notifications, at: 0)
                } else {
                    let notifications = notifications![0 ... index]
                    self.notifications.insert(contentsOf: notifications, at: 0)
                }
                DispatchQueue.main.async(execute: {self.tableView.reloadData()})
            }
        }
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.notifications.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationViewCell", for: indexPath) as? NotificationTableViewCell else {
            print("cell isn't a status view cell")
            return tableView.dequeueReusableCell(withIdentifier: "NotificationViewCell", for: indexPath)
        }
        
        let notification = notifications[indexPath.row]
        
        cell.index = indexPath.row
        
        if notification.status != nil {
            var status = notification.status!
            
            if status.reblog != nil {
                status = status.reblog!
            }
            
            if status.account.displayName.isEmpty {
                cell.userLabel.text = status.account.acct // use username if displayname is empty
            } else {
                cell.userLabel.text = status.account.displayName
            }
            
            switch notification.type {
            case .favourite:
                Helper.DownloadImageToView(url: notification.account.avatar, view: cell.relatedAvatarView)
                cell.relatedAvatarView.isHidden = false
                cell.typeView.image = UIImage(named: "heart")
                cell.typeView.isHidden = false
                var user = ""
                if notification.account.displayName.isEmpty {
                    user = notification.account.acct // use username if displayname is empty
                } else {
                    user = notification.account.displayName
                }
                user += " has liked your status!"
                cell.userLabel.text = user
            case .follow:
                cell.relatedAvatarView.isHidden = true
                cell.typeView.isHidden = true
            case .mention:
                cell.relatedAvatarView.isHidden = true
                cell.typeView.isHidden = true
            case .reblog:
                Helper.DownloadImageToView(url: notification.account.avatar, view: cell.relatedAvatarView)
                cell.relatedAvatarView.isHidden = false
                cell.typeView.image = UIImage(named: "reblog")
                cell.typeView.isHidden = false
            }
            
            cell.statusLabel.text = Helper.ExtractContent(content: Helper.EscapeString(string: status.content))
            
            cell.setNeedsDisplay()
            
            Helper.DownloadImageToView(url: status.account.avatar, view: cell.avatarView!)
        } else {
            if (notification.type == NotificationType.follow) {
                cell.userLabel.text = notification.account.acct
                cell.statusLabel.text = "has followed you!"
                cell.relatedAvatarView.isHidden = true
                cell.typeView.isHidden = true
                
                Helper.DownloadImageToView(url: notification.account.avatar, view: cell.avatarView!)
            }
        }
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let notif = notifications[indexPath.row]
        if (notif.type == NotificationType.follow) {
            performSegue(withIdentifier: "openProfile", sender: cell)
        } else {
            performSegue(withIdentifier: "openStatus", sender: cell)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cell = sender as! NotificationTableViewCell
        if segue.identifier! == "openProfile" {
            if let destination = segue.destination as? ProfileViewController {
                destination.profile_id = notifications[cell.index].account.id
                destination.client = client
            }
        } else if segue.identifier! == "openStatus" {
            do {
                if let destination = segue.destination as? StatusViewController {
                    guard let status = notifications[cell.index].status else {
                        throw NotificationError.NotStatus
                    }
                    destination.status = status
                    destination.client = client
                }
            } catch {
                performSegue(withIdentifier: "openProfile", sender: sender)
            }
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //scrollview is at bottom
        if (Int(scrollView.contentOffset.y + scrollView.frame.size.height) == Int(scrollView.contentSize.height + scrollView.contentInset.bottom)) {
            print("scroll at bottom")
        }
    }
    
}

