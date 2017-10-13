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
    @IBOutlet weak var domainText: UITextField!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    private var auth_session: SFAuthenticationSession?
    
    private var username = ""
    private var password = ""
    
    static let LOGIN_SEGUE = "login_segue"
    static let APP_NAME = "Swiffty"
    static let CLIENT_NAME = "\(RootViewController.APP_NAME): (\(UIDevice.current.name))"
//    static let REDIRECT_URI = "urn:ietf:wg:oauth:2.0:oob" // specified by mastodon
    static let REDIRECT_URI = "\(RootViewController.APP_NAME.lowercased())://authorized"
    static let PERMISSIONS = "read%20write%20follow"
    static var MASTODON_SETTINGS = MastodonSettings(url: "", client_id: "", client_secret: "", id: -1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        indicator.isHidden = true
        domainText.returnKeyType = .done
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
    
    @objc
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
            
            self.auth_session = SFAuthenticationSession(
                url: oauth_url!,
                callbackURLScheme: nil,
                completionHandler: { (completed_url, error) in
                    if error != nil {
                        Helper.createAlert(controller: self, title: "OAuth Error", message: "Didn't recieve oauth token", preferredStyle: .alert)
                        self.onFailure()
                    }
                    if let completed_url = completed_url {
                        print(completed_url.absoluteString)
                        let url_components = URLComponents(string: completed_url.absoluteString)
                        let auth_code = url_components?.queryItems?.first(where: { $0.name == "code" })?.value
                        print(auth_code!)
                        
                        if let auth_code = auth_code {
                            var request = URLRequest(url: URL(string: "\(url)/oauth/token")!)
                            request.httpMethod = "POST"
                            let postString = "grant_type=authorization_code" +
                                "&client_id=\(RootViewController.MASTODON_SETTINGS.client_id)" +
                                "&client_secret=\(RootViewController.MASTODON_SETTINGS.client_secret)" +
                                "&code=\(auth_code)&redirect_uri=\(RootViewController.REDIRECT_URI)"
                            request.httpBody = postString.data(using: .utf8)

                            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                                let responseString = String(data: data!, encoding: .utf8)
                                print(responseString!)
                                
                                let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                                
                                if let json_dict = json as? [String: Any] {
                                    print(json_dict)
                                    let info = AccessInfo(accessToken: json_dict["access_token"] as! String, authCode: auth_code, url: url)
                                    AccessInfo.saveAccessInfo(info: info!)
                                    let client = Client(baseURL: url, accessToken: info!.accessToken)
                                    DispatchQueue.main.async {
                                        self.afterLogin(client: client, sender: sender)
                                    }
                                }
                            }

                            task.resume()
                        } else {
                            print("couldn't get refresh token")
                        }
                    }
                }
            )
            let success = self.auth_session!.start()
            if !success {
                self.onFailure()
            }
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
        
        print(exists)
        print(domain)
        if (exists) {
            prepareMastodon(url: domain, sender: sender)
        }
        else {
            Helper.createAlert(controller: self, title: "Instance Failed", message: "We couldn't connect to this instance!", preferredStyle: UIAlertControllerStyle.alert)
            onFailure()
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
        textField.resignFirstResponder()
        return false
    }
}
