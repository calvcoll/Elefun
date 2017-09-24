//
//  FirstViewController.swift
//  Swiftty
//
//  Created by Calv Collins on 29/07/2017.
//  Copyright © 2017 Calv Collins. All rights reserved.
//

import UIKit
import MastodonKit

class TimelineViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var client: Client!
    var accessInfo: AccessInfo!
    var statuses: [Status] = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tootButton: UIButton!
    
    var loaded = true
    
    override func awakeFromNib() {
        self.accessInfo = AccessInfo.loadAccessInfo()!
        self.client = Client(baseURL: accessInfo.url, accessToken: accessInfo.accessToken)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        /////////////////////////////////////////////////
        if (self.statuses.count > 0) {
            let store = StatusStore(statuses: self.statuses, lastStatus: self.statuses.last!) // fix to be top of view once scrolled
            if let store = store {
                StatusStore.saveStatuses(info: store)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Do any additional setup after loading the view, typically from a nib.
        
        self.tableView!.rowHeight = 75
        
        if let store = StatusStore.loadStatuses() {
            self.statuses = store.statuses
            //scroll to status /////////////////////////////////////////////////
            self.tableView.reloadData()
        } else {
            getStatuses()
        }
        
        self.tableView.refreshControl = UIRefreshControl()
        self.tableView.refreshControl!.backgroundColor = UIColor.white
        self.tableView.refreshControl!.tintColor = UIColor.darkGray
        self.tableView.refreshControl!.addTarget(self, action: #selector(refresh(refreshControl:)), for: UIControlEvents.valueChanged)
    }
    
    @objc func refresh(refreshControl: UIRefreshControl) {
        getStatuses()
    }
    
    func getStopIndex(statuses: [Status]) -> Int {
        var index = -1
        var i = 0

        if self.statuses.count > 0 {
            for status in statuses {
                if status.id == self.statuses[0].id {
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
        client.run(Timelines.home()) { (statuses, error) in
            DispatchQueue.main.async {
                if self.tableView.refreshControl != nil {
                    self.tableView.refreshControl!.endRefreshing()
                }
            }
            if error != nil {
                print(error!)
                return
            }
            if statuses != nil {
                let index = self.getStopIndex(statuses: statuses!)
                if index == -1 {
                    self.statuses = statuses!
                } else if index == 0 {
                } else if index == -2 {
                    let statuses = statuses!
                    self.statuses.insert(contentsOf: statuses, at: 0)
                } else {
                    let statuses = statuses![0 ... index-1]
                    self.statuses.insert(contentsOf: statuses, at: 0)
                }
                DispatchQueue.main.async(execute: {self.tableView.reloadData()})
            }
        }
        
    }
    
    func getStatusesFrom(_ status: Status) {
        client.run(Timelines.home(range: RequestRange.max(id: status.id, limit: 20))) { (statuses, error) in
            if error != nil {
                print(error!)
                return
            }
            if statuses != nil {
                self.statuses.append(contentsOf: statuses!)
                DispatchQueue.main.async(execute: {self.tableView.reloadData()})
            }
            DispatchQueue.main.async {
                if self.tableView.refreshControl != nil {
                    self.tableView.refreshControl!.endRefreshing()
                }
            }
            self.loaded = true
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.statuses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationViewCell", for: indexPath) as? NotificationTableViewCell else {
            print("cell isn't a status view cell")
            return tableView.dequeueReusableCell(withIdentifier: "NotificationViewCell", for: indexPath)
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
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if loaded && indexPath.row == statuses.count-1 {
            getStatusesFrom(statuses.last!)
            loaded = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? StatusViewController {
            let cell = sender as! NotificationTableViewCell
            let status = statuses[cell.index]
            destination.status = status
            destination.client = client
        } else if let destination = segue.destination as? TootViewController {
            destination.client = client
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //scrollview is at bottom
        if !statuses.isEmpty {
            // doesnt work on ios11 (or maybe just iphone x)
            if (Int(scrollView.contentOffset.y + scrollView.frame.size.height) == Int(scrollView.contentSize.height + scrollView.contentInset.bottom)) {
                print("scroll at bottom, loaded = \(loaded)")
                if loaded {
                    getStatusesFrom(statuses.last!)
                    loaded = false
                }
            }

        }
    }

}

