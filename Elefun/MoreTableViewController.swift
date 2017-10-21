//
//  MoreTableViewController.swift
//  Elefun
//
//  Created by Calv Collins on 12/10/2017.
//  Copyright © 2017 Calv Collins. All rights reserved.
//

import UIKit

class MoreTableViewController: UITableViewController {
    
    static let HOME_REFRESH = "home_refresh"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    @IBAction func onClearLoginPress(_ sender: UIButton) {
        let alert = UIAlertController(title: "Delete Login Data", message: "This will require you to reauthenticate.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
            let success = AccessInfo.clearAccessInfo()
            if !success {
                Helper.createAlert(controller: self, title: "Deletion failed!", message: "Session information could not be deleted.", preferredStyle: .alert)
            } else {
                self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true) {

        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
