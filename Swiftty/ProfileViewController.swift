//
//  ProfileViewController.swift
//  Swiftty
//
//  Created by Calv Collins on 07/08/2017.
//  Copyright © 2017 Calv Collins. All rights reserved.
//

import UIKit
import MastodonKit

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var followBackImage: UIImageView!
    @IBOutlet weak var headerView: UIImageView!
    
    @IBOutlet weak var tableView: StatusContextTableView!
    
    var client: Client!
    var profile_id: Int!
    
    var account: Account!
    var toots: [Status]!
    var following: Bool = false
    var followingYou: Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.rowHeight = 75
        client.run(Accounts.account(id: profile_id)) { (profile, error) in
            if let profile = profile {
                self.account = profile
                
                DispatchQueue.main.async(execute: {
                    self.client.run(Accounts.currentUser(), completion: { (own_account, error) in
                        if let own_account = own_account {
                            if self.account.id == own_account.id {
                                self.isSameAccount()
                            }
                        }
                    })
                    
                    if self.account.displayName.isEmpty {
                        self.usernameLabel.text = self.account.acct // use username if displayname is empty
                    } else {
                        self.usernameLabel.text = self.account.displayName
                    }
                    
                    self.bioLabel.text = Helper.ExtractContent(content: Helper.EscapeString(string: self.account.note))
                })
                Helper.DownloadImageToView(url: self.account.avatar, view: self.avatarView!)
                Helper.DownloadImageToView(url: self.account.header, view: self.headerView!)
            }
        }
        
        self.avatarView!.isUserInteractionEnabled = true
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(self.onAvatarTap(_:)))
        self.avatarView!.addGestureRecognizer(avatarTap)
        
        self.headerView!.isUserInteractionEnabled = true
        let headerTap = UITapGestureRecognizer(target: self, action: #selector(self.onHeaderTap(_:)))
        self.headerView!.addGestureRecognizer(headerTap)
    }
    
    func isSameAccount() {
        self.followButton.isHidden = true
        self.followBackImage.isHidden = true
    }
    
    @objc func onHeaderTap (_ sender: Any?) {
        performSegue(withIdentifier: "openHeaderImageLink", sender: self.avatarView!)
    }
    
    @objc func onAvatarTap (_ sender: Any?) {
        performSegue(withIdentifier: "openProfileImageLink", sender: self.avatarView!)
    }

    func downloadToots() {
        client.run(Accounts.statuses(id: profile_id)) { (statuses, error) in
            if let statuses = statuses {
                self.toots = statuses
                
                DispatchQueue.main.async(execute: {
                    self.tableView.statuses = self.toots
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getFollowed()
        getIsFollowing()
        downloadToots()
        // Do any additional setup after loading the view.
    }
    
    func getFollowed() {
        client.run(Accounts.currentUser()) { (user, errors) in
            if let user = user {
                self.client.run(Accounts.following(id: user.id), completion: { (followers, errors) in
                    if let followers = followers {
                        var follows = false
                        for follower in followers {
                            if self.profile_id == follower.id {
                                follows = true
                                break;
                            }
                        }
                        
                        if follows {
                            self.following = true
                        }
                        
                        Helper.FollowButtonStyling(button: self.followButton, following: self.following)
                    }
                })
            }
        }
    }
    
    func getIsFollowing() {
        client.run(Accounts.currentUser()) { (user, errors) in
            if let user = user {
                self.client.run(Accounts.following(id: self.profile_id), completion: { (followers, errors) in
                    if let followers = followers {
                        var follows = false
                        for follower in followers {
                            if user.id == follower.id {
                                follows = true
                                break;
                            }
                        }
                        
                        if follows {
                            self.followingYou = true
                        }
                        
                        DispatchQueue.main.async(execute: {self.followBackImage.isHidden = !self.followingYou})
                    }
                })
            }
        }
    }
    
    
    @IBAction func followButton(_ sender: UIButton) {
        self.following = !self.following
        if self.following {
            client.run(Accounts.follow(id: profile_id)) { (account, error) in
                if error != nil {
                    Helper.createAlert(controller: self, title: "Follow Error", message: "Unable to follow", preferredStyle: UIAlertControllerStyle.alert)
                }
            }
        } else {
            client.run(Accounts.unfollow(id: profile_id)) { (account, error) in
                if error != nil {
                    Helper.createAlert(controller: self, title: "Follow Error", message: "Unable to unfollow", preferredStyle: UIAlertControllerStyle.alert)
                }
            }
        }
        Helper.FollowButtonStyling(button: self.followButton, following: self.following)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "selectProfileStatus" {
            if let cell = sender as? NotificationTableViewCell, let destination = segue.destination as? StatusViewController{
                let toot = toots[cell.index]
                destination.status = toot
                destination.client = client
            }
        }
        
        if segue.identifier == "openProfileImageLink" {
            if let destination = segue.destination as? WebViewController {
                destination.url = self.account.avatar
            }
        }
        
        if segue.identifier == "openHeaderImageLink" {
            if let destination = segue.destination as? WebViewController {
                destination.url = self.account.header
            }
        }
        
    }

}
