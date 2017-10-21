//
//  WebViewController.swift
//  Elefun
//
//  Created by Calv Collins on 07/08/2017.
//  Copyright © 2017 Calv Collins. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var navBar: UINavigationItem!
    
    var url: String!
    
    override func viewDidLoad() {
        self.navigationItem.title = self.url
        
        let request = URLRequest(url: URL(string: self.url)!)
        webView.loadRequest(request)
        
        navBar.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(openInSafari(sender:)))
        // Do any additional setup after loading the view.
    }
    
    @objc func openInSafari(sender: Any?) {
        UIApplication.shared.open(URL(string: self.url)!, options: [:], completionHandler: { (success) in
            if !success {
                Helper.createAlert(controller: self, title: "Can't open", message: "Can't open URL", preferredStyle: .alert)
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
