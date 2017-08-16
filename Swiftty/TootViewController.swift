//
//  TootViewController.swift
//  Swiftty
//
//  Created by Calv Collins on 13/08/2017.
//  Copyright © 2017 Calv Collins. All rights reserved.
//

import UIKit
import MastodonKit

class TootViewController: UIViewController {
    
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var tootText: UITextView!
    @IBOutlet weak var charCountView: UILabel!
    @IBOutlet weak var visibilityPicker: UIPickerView!
    
    var client: Client!
    let visibilities = [Visibility.public, Visibility.private, Visibility.direct, Visibility.unlisted]
    
    var sensitive: Bool?
    var mediaIDs: [Int]? = []
    var spoilerText: String?
    var visibility: Visibility?
    var replyID: Int?
    var replyStatus: Status?
    
    var charCount: Int = 0
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navBar.rightBarButtonItem = UIBarButtonItem(title: "Toot!", style: .done, target: self, action: #selector(sendToot(sender:)))
        
        var mentionString = ""
        if replyID != nil || self.replyStatus != nil {
            mentionString += "@\(self.replyStatus!.account.acct) "
            if !replyStatus!.mentions.isEmpty {
                for mention in replyStatus!.mentions {
                    mentionString += "@\(mention.acct) "
                }
            }
        }
        self.tootText.text = mentionString
    }
    
    func sendToot (sender: Any?) {
        if (self.charCount <= 500 && self.charCount > 0) {
            client.run(Statuses.create(status: tootText.text!, replyToID: replyID, mediaIDs: mediaIDs!, spoilerText: spoilerText, visibility: visibilities[visibilityPicker.selectedRow(inComponent: 0)]), completion: { (status, error) in
                    if error != nil {
                        Helper.createAlert(controller: self, title: "Cannot Toot!", message: "Can't toot your message to your instance!", preferredStyle: .alert)
                    } else {
                        DispatchQueue.main.async(execute: {
                            self.tootText.text = ""
                            self.navigationController?.popViewController(animated: true)
                    })
                }
            })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension TootViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return visibilities.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch visibilities[row]{
        case Visibility.public: return "Public"
        case Visibility.private: return "Private"
        case Visibility.direct: return "Direct Message"
        case Visibility.unlisted: return "Unlisted"
        }
    }
}

extension TootViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty {
            self.charCount = 0
        } else {
            self.charCount = textView.text!.characters.count
        }
        self.charCountView.text = "\(500 - self.charCount)"
        
        if self.charCount > 500 {
            self.charCountView.textColor = UIColor.red
        } else {
            self.charCountView.textColor = UIColor.black
        }
    }
}
