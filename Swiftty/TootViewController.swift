//
//  TootViewController.swift
//  Swiftty
//
//  Created by Calv Collins on 13/08/2017.
//  Copyright © 2017 Calv Collins. All rights reserved.
//

import UIKit
import MastodonKit

class TootViewController: UIViewController { //TO-DO: Multiple image semaphore, currently could be triggered by any image upload
    
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var tootText: UITextView!
    @IBOutlet weak var charCountView: UILabel!
    @IBOutlet weak var visibilityPicker: UIPickerView!
    
    @IBOutlet weak var uploadImage1: UIImageView!
    @IBOutlet weak var uploadImage2: UIImageView!
    @IBOutlet weak var uploadImage3: UIImageView!
    @IBOutlet weak var uploadImage4: UIImageView!
    
    var uploadedImages: [UIImageView] = []
    
    @IBOutlet weak var uploadingIndicator: UIActivityIndicatorView!
    
    var client: Client!
    let visibilities = [Visibility.public, Visibility.private, Visibility.direct, Visibility.unlisted]
    
    var sensitive: Bool?
    var mediaIDs: [Int] = []
    var spoilerText: String?
    var visibility: Visibility?
    var replyID: Int?
    var replyStatus: Status?
    
    var charCount: Int = 0
    var mediaBlocks: [Bool] = []
    
    let imagePickerController = UIImagePickerController()
    
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
    
    @objc func sendToot (sender: Any?) {
        if self.mediaBlocks.isEmpty {
            if (self.charCount <= 500 && self.charCount > 0) {
                client.run(Statuses.create(status: tootText.text!, replyToID: replyID, mediaIDs: mediaIDs, spoilerText: spoilerText, visibility: visibilities[visibilityPicker.selectedRow(inComponent: 0)]), completion: { (status, error) in
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
        } else {
            Helper.createAlert(controller: self, title: "Image Upload", message: "Sorry, you have to wait till your image is uploaded", preferredStyle: .alert)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.uploadedImages = [uploadImage1, uploadImage2, uploadImage3, uploadImage4]
        self.uploadingIndicator.isHidden = true
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func uploadImagePressed(_ sender: UIButton) {
        var freeImageSlot = false
        
        for view in uploadedImages {
            if (view.image == nil) {
                freeImageSlot = true
            }
        }
        
        if freeImageSlot {
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.delegate = self
            present(imagePickerController, animated: true, completion: nil)
        }
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

extension TootViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage? {
            self.mediaBlocks.append(true)
            self.uploadingIndicator.startAnimating()
            self.uploadingIndicator.isHidden = false
            let imageData = UIImagePNGRepresentation(pickedImage)
            
            for view in uploadedImages {
                if (view.image == nil) {
                    view.image = pickedImage
                    view.isHidden = false
                    break
                }
            }
            
            client.run(Media.upload(media: .png(imageData)), completion: { attachment, error in
                if let attachment = attachment {
                    self.mediaIDs.append(attachment.id)
                }
                if error != nil {
                    Helper.createAlert(controller: self.imagePickerController, title: "Upload Failed", message: "Couldn't upload image", preferredStyle: .alert)
                }
                let _ = self.mediaBlocks.popLast();
                if self.mediaBlocks.isEmpty {
                    self.uploadingIndicator.stopAnimating()
                    self.uploadingIndicator.isHidden = true
                }
            })
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
