//
//  StatusViewController.swift
//  Swiftty
//
//  Created by Calv Collins on 31/07/2017.
//  Copyright © 2017 Calv Collins. All rights reserved.
//

import UIKit
import MastodonKit

class StatusViewController: UIViewController {
//
//    
//    
//    
//    TO DO - MAKE ANCESTOR TABLE VIEW IN SCROLL UPWARDS LIKE TWITTER - THEN REMOVE CONDITIONALS
//    
//    
//    
//    
    @IBOutlet weak var navBar: UINavigationItem!
    
    @IBOutlet weak var ancestorsTableView: StatusContextTableView!
    @IBOutlet weak var descendantsTableView: StatusContextTableView!
    
    @IBOutlet weak var descendantsEmptyLabel: UILabel!
    
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var avatarView: UIImageView!
    
    @IBOutlet weak var link1Button: UIButton!
    @IBOutlet weak var link2Button: UIButton!
    @IBOutlet weak var link3Button: UIButton!
    
    @IBOutlet weak var heartView: UIButton!
    @IBOutlet weak var retootView: UIButton!
    @IBOutlet weak var heartTickButton: UIButton!
    @IBOutlet weak var retootTickButton: UIButton!
    
    var status: Status!
    var client: Client!
    var descendants: [Status] = []
    var ancestors: [Status] = []
    
    let accessInfo = AccessInfo.loadAccessInfo()!
    static let CELL_NAME = "replyStatuses"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navBar.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .reply, target: self, action: #selector(replyToStatus(sender:)))
        // Do any additional setup after loading the view.
        downloadContext(originalStatus: status)
        
        
        let links = Helper.ExtractLinks(content: Helper.EscapeString(string: status.content))
        var link_i = 0
        if (links.count > 0) {
            for link in links {
                switch (link_i){
                case 0:
                    link1Button.setTitle(link, for: .normal)
                    link1Button.isHidden = false
                case 1:
                    link2Button.setTitle(link, for: .normal)
                    link2Button.isHidden = false
                case 2:
                    link3Button.setTitle(link, for: .normal)
                    link3Button.isHidden = false
                default:
                    print("u wot m8")
                }
                link_i += 1
            }
        }
    }
    
    func downloadContext(originalStatus: Status) {
        client.run(Statuses.context(id: originalStatus.id)) { (context, error) in
            if error != nil {
                print(error!)
                return
            }
            if let context = context {
                self.descendants = context.descendants
                self.ancestors = context.ancestors
                
                self.descendantsTableView.statuses = self.descendants
                if (self.ancestorsTableView != nil) {
                    self.ancestorsTableView.statuses = self.ancestors
                }
                
                DispatchQueue.main.async(execute: {
                    self.descendantsTableView.reloadData()
                    if (self.ancestorsTableView != nil) {
                        self.ancestorsTableView.reloadData()
                    }
                    
                    if (self.descendants.count == 0) {
                        self.descendantsTableView.makeGray()
                        self.descendantsEmptyLabel.isHidden = false
                    }
                    if (self.ancestors.count == 0 && self.ancestorsTableView != nil) {
                        self.ancestorsTableView.makeGray()
                    }
                })
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if status.reblog != nil {
            status = status.reblog!
        }
        
        if status.account.displayName.isEmpty {
            userLabel.text = status.account.acct // use username if displayname is empty
        } else {
            userLabel.text = status.account.displayName
        }
        
        statusLabel.text = Helper.ExtractContent(content: Helper.EscapeString(string: status.content))
        
        Helper.DownloadImageToView(url: status.account.avatar, view: self.avatarView!)
        
        self.avatarView!.isUserInteractionEnabled = true
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(self.onAvatarTap(_:)))
        self.avatarView!.addGestureRecognizer(avatarTap)
    }
    
    func onAvatarTap (_ sender: Any?) {
        performSegue(withIdentifier: "openProfileFromStatus", sender: self.avatarView!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "openLink", sender: sender)
    }
    
    @IBAction func heartButtonPressed(_ sender: Any) {
        client.run(Statuses.favourite(id: status.id)) { (status, error) in
            if error != nil {
                Helper.createAlert(controller: self, title: "Like error", message: "Like failed to submit!", preferredStyle: .alert)
            }
        }
        UIView.transition(with: heartTickButton, duration: 0.4, options: .transitionCrossDissolve, animations: {
            self.heartTickButton.isHidden = false
        }) { (done) in
            //
        }
    }
    
    @IBAction func retootButtonPressed(_ sender: Any) {
        client.run(Statuses.reblog(id: status.id)) { (status, error) in
            if error != nil {
                Helper.createAlert(controller: self, title: "Retoot error", message: "Retoot failed to submit!", preferredStyle: .alert)
            }
        }
        UIView.transition(with: retootTickButton, duration: 0.4, options: .transitionCrossDissolve, animations: {
            self.retootTickButton.isHidden = false
        }) { (done) in
            //
        }
    }
    
    @IBAction func tickButtonPressed(_ sender: Any) {
        let button = sender as? UIButton
        UIView.transition(with: button!, duration: 0.4, options: .transitionCrossDissolve, animations: {
            button!.isHidden = true
        }) { (done) in
            //
        }
    }
    
    func replyToStatus(sender: Any?) {
        performSegue(withIdentifier: "replyTo", sender: sender)
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "replySelect" {
            if let cell = sender as? NotificationTableViewCell, let destination = segue.destination as? StatusViewController{
                let reply = descendants[cell.index]
                destination.status = reply
                destination.client = client
            }
        } else if segue.identifier == "openLink" {
            if let button = sender as? UIButton, let destination = segue.destination as? WebViewController{
                destination.url = button.title(for: .normal)!
            }
        } else if segue.identifier == "openProfileFromStatus" {
            if let destination = segue.destination as? ProfileViewController{
                destination.profile_id = status.account.id
                destination.client = self.client!
            }
        } else if segue.identifier == "replyTo" {
            if let destination = segue.destination as? TootViewController {
                destination.replyID = self.status.id
                destination.replyStatus = self.status
                destination.client = self.client!
            }
        }
    }

}
