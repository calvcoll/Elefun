//
//  MoreTableViewController.swift
//  Swiftty
//
//  Created by Calv Collins on 12/10/2017.
//  Copyright © 2017 Calv Collins. All rights reserved.
//

import UIKit

class MoreTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    @IBAction func onClearLoginPress(_ sender: UIButton) {
        var success = true
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
            success = AccessInfo.clearAccessInfo()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true) {
            if !success {
                Helper.createAlert(controller: self, title: "Deletion failed!", message: "Session information could not be deleted.", preferredStyle: .alert)
            }
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
