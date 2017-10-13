//
//  RootViewController.swift
//  Swiftty
//
//  Created by Calv Collins on 29/07/2017.
//  Copyright © 2017 Calv Collins. All rights reserved.
//

import UIKit
import SafariServices

import MastodonKit

class RootViewController: UIViewController {

    struct MastodonSettings {
        let url: String
        let client_id: String
        let client_secret: String
        let id: Int
    }
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var userNameText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var domainText: UITextField!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    private var username = ""
    private var password = ""
    
    static let LOGIN_SEGUE = "login_segue"
    static let CLIENT_NAME = "Swiftty: (\(UIDevice.current.name))"
    static let REDIRECT_URI = "urn:ietf:wg:oauth:2.0:oob" // specified by mastodon
    static let PERMISSIONS = "read%20write%20follow"
    static var MASTODON_SETTINGS = MastodonSettings(url: "", client_id: "", client_secret: "", id: -1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        indicator.isHidden = true

        domainText.returnKeyType = UIReturnKeyType.done
        domainText.delegate = self
        
        if let info = AccessInfo.loadAccessInfo() {
            let client = Client(baseURL: info.url, accessToken: info.accessToken)
            self.afterLogin(client: client, sender: self)
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func domainExists(url: NSURL) -> Bool {
        if (!UIApplication.shared.canOpenURL(url as URL)) { //checks if valid
            return false
        }
        var statusCode = -1
        let session = URLSession.shared.dataTask(with: url as URL) {loc, response, error in //checks if gets response
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
            }
            if (error != nil) {
                statusCode = -2
            }
        }
        session.resume()
        
        while (statusCode == -1) {}
        if (statusCode != -2) {
            return true
        }
        return false
    }
    
    func prefixHTTP(url: String) -> String {
        if (url.hasPrefix("http:") || url.hasPrefix("https:")) {
            return url
        }
        else {
            return "https://" + url
        }
    }
    
    func prepareMastodon(url: String, sender: Any) {
        let url = prefixHTTP(url: url)
        
//        let client = Client(baseURL: url)
//        let request = Clients.register(
//            clientName: RootViewController.CLIENT_NAME,
//            scopes: [.read, .write, .follow]
//        )
//
//        client.run(request) { (app, error) in
//            if let error = error {
//                print(error)
//                self.onFailure()
//            }
//            if let app = app {
//                RootViewController.MASTODON_SETTINGS = MastodonSettings(url: url, client_id: app.clientID, client_secret: app.clientSecret, id: app.id)
//                self.onSecrets(url: url, sender: sender)
//            } else {
//                self.onFailure() // some reason always ends here, leaving for future fix
//            }
//        }
        
        var request = URLRequest(url: URL(string: "\(url)/api/v1/apps")!)
        request.httpMethod = "POST"
        let postString = "client_name=\(RootViewController.CLIENT_NAME)&redirect_uris=\(RootViewController.REDIRECT_URI)&scopes=\(RootViewController.PERMISSIONS)"
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {                                                 // check for fundamental networking error
                    print("error=\(error!)")
                    Helper.createAlert(controller: self, title: "Network Error", message: "We couldn't connect to \(url)", preferredStyle: UIAlertControllerStyle.alert)
                    return
                }

                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                    print("statusCode should be 200, but is \(httpStatus.statusCode)")
                    print("response = \(response!)")

                    if httpStatus.statusCode == 429 {
                        Helper.createAlert(controller: self, title: "Rate Limited", message: "Sorry you've been rate limited by \(url)", preferredStyle: .alert)
                    }
                }

                let responseString = String(data: data, encoding: .utf8)!
                print("responseString = \(responseString)")
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode == 200 {
                    let json = try? JSONSerialization.jsonObject(with: data, options: [])

                    if let json_dict = json as? [String: Any] {
                        print(json_dict)
                        RootViewController.MASTODON_SETTINGS = MastodonSettings(url: url, client_id: json_dict["client_id"]! as! String, client_secret: json_dict["client_secret"]! as! String, id: Int(json_dict["id"] as! String)!)
                    }

                    self.onSecrets(url: url, sender: sender)
                }
            }
        }
        task.resume()
    }
    
    func onSecrets(url: String, sender: Any) {
        if let info = AccessInfo.loadAccessInfo() {
            print("using accessinfo")
            let client = Client(baseURL: url, accessToken: info.accessToken)
            self.afterLogin(client: client, sender: sender)
        } else {
            
            //USING OAUTH
            
            let oauth_url = URL(string: "\(url)/oauth/authorize?scope=\(RootViewController.PERMISSIONS)" +
                "&response_type=code&redirect_uri=\(RootViewController.REDIRECT_URI)" +
                "&client_id=\(RootViewController.MASTODON_SETTINGS.client_id)"
            )
            
            SFAuthenticationSession(
                url: oauth_url!,
                callbackURLScheme: "",
                completionHandler: { (url, error) in
//                        if error != nil {
//                            Helper.createAlert(controller: self, title: "OAuth Erorr", message: "Didn't recieve oauth token", preferredStyle: .alert)
//                        }
//                        if let url = url {
//                            print(url)
//                        }
                    print(url as Any,error as Any)
                }
            ).start()
            self.onFailure()
            
            // USING OLD AUTH
//            DispatchQueue.main.async {
//                let login = Login.silent(
//                    clientID: RootViewController.MASTODON_SETTINGS.client_id,
//                    clientSecret: RootViewController.MASTODON_SETTINGS.client_secret,
//                    scopes: [.read, .write, .follow],
//                    username: self.username,
//                    password: self.password
//                )
//
//                let client = Client(baseURL: url)
//
//                client.run(login) { loginSettings, error in
//                    DispatchQueue.main.async {
//                        if let loginSettings = loginSettings {
//                            print("log in settings" + loginSettings.accessToken)
//                            let info = AccessInfo(accessToken: loginSettings.accessToken, url: RootViewController.MASTODON_SETTINGS.url, user: self.username)
//                            AccessInfo.saveAccessInfo(info: info!)
//
//                            client.accessToken = info!.accessToken
//                            self.afterLogin(client: client, sender: sender)
//                        }
//                        if error != nil {
//                            Helper.createAlert(controller: self, title: "Username/Password", message: "Username/Password Incorrect", preferredStyle: .alert)
//                            self.onFailure()
//                        }
//                    }
//                }
//            }
        }
    }
    
    func afterLogin(client: Client, sender: Any) {
        print(client.accessToken!)
        
        client.run(Accounts.currentUser()) { (account, error) in
            DispatchQueue.main.async {
                if (error != nil) {
                    print(error!)
                }
                if (account != nil) {
                    print(account!.displayName)
                }
                self.performSegue(withIdentifier: RootViewController.LOGIN_SEGUE, sender: sender)
            }
        }
    }
    
    @IBAction func onLoginPress(_ sender: Any) {
        loginButton.isEnabled = false
        domainText.isEnabled = false
        indicator.isHidden = false
        indicator.startAnimating()
        let domain = domainText.text!
        let exists = domainExists(url: NSURL(string: prefixHTTP(url: domain))!)
        
        username = self.userNameText.text!
        password = self.passwordText.text!
        
        print(exists)
        print(domain)
        if (username.isEmpty || password.isEmpty) {
            Helper.createAlert(controller: self, title: "No username/password", message: "You haven't entered a username, or a password.", preferredStyle: UIAlertControllerStyle.alert)
            onFailure()
        } else {
            if (exists) {
                prepareMastodon(url: domain, sender: sender)
            }
            else {
                Helper.createAlert(controller: self, title: "Instance Failed", message: "We couldn't connect to this instance!", preferredStyle: UIAlertControllerStyle.alert)
                onFailure()
            }
        }
    }
    
    func onFailure() {
        DispatchQueue.main.async {
            self.indicator.stopAnimating()
            self.indicator.isHidden = true
            self.domainText.isEnabled = true
            self.loginButton.isEnabled = true
        }
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

extension RootViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        DispatchQueue.main.async(execute: {
//            if self.view != nil {
//                self.view.endEditing(true)
//            }
//        })
        textField.resignFirstResponder()
        return false
    }
}
