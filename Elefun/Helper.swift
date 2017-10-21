//
//  Helper.swift
//  Elefun
//
//  Created by Calv Collins on 31/07/2017.
//  Copyright © 2017 Calv Collins. All rights reserved.
//

import Foundation
import UIKit
import Kanna

class Helper {
    
    static let debugImageResponse = false
    static let lightGray: UIColor = UIColor.init(white: 0.95, alpha: 1)
    static let accessInfo: AccessInfo = AccessInfo.loadAccessInfo()!
    
    class func prefixURLIfMissing(url: String) -> String {
        if (url.hasPrefix("http:") || url.hasPrefix("https:")) {
            return url
        }
        else {
            return accessInfo.url + url
        }
    }
    
    class func DownloadImageToView (url: String, view: UIImageView) {
        let url = URL(string: prefixURLIfMissing(url: url))!
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            // The download has finished.
            if let e = error {
                print("Error downloading avatar: \(e)")
            } else {
                if let res = response as? HTTPURLResponse {
                    if debugImageResponse {
                        print("Downloaded avatar with response code \(res.statusCode)")
                    }
                    if let imageData = data {
                        if let image = UIImage(data: imageData) {
                            DispatchQueue.main.async(execute: {view.image = image})
                        } else {
                            print("Image data couldn't be read. \(url)")
                        }
                    } else {
                        print("Couldn't get image: Image is nil")
                    }
                } else {
                    print("Couldn't get response code for some reason")
                }
            }
            }.resume()
    }
    
    class func ExtractLinks (content: String) -> [String] {
        var links: [String] = []
//        if let doc = HTML(html: content, encoding: .utf8) {
//            for link in doc.css("a, link") {
//                let text = link.text!
//                if let classes = link["class"] {
//                    if (classes.contains("mention hashtag")) { //is link to hashtag
//                        print(text)
//                    } else if (classes.contains("u-url mention")) { //is link to username mention
//                        print("mentioning \(text)")
//                    } else if (classes.isEmpty) {
//                        links.append(text)
//                    }
//                } else {
////                    if (text.contains("\(accessInfo.url)/media/")) { //media
////                        print("media \(text)")
//                    links.append(text)
////                    } else { // normal url
////                        print("url \(text)")
////                    }
//                }
//            }
//        }
        do {
            let doc = try HTML(html: content, encoding: .utf8)
            for link in doc.css("a, link") {
                let text = link.text!
                if let classes = link["class"] {
                    if (classes.contains("mention hashtag")) { //is link to hashtag
                        print(text)
                    } else if (classes.contains("u-url mention")) { //is link to username mention
                        print("mentioning \(text)")
                    } else if (classes.isEmpty) {
                        links.append(text)
                    }
                } else {
                    //                    if (text.contains("\(accessInfo.url)/media/")) { //media
                    //                        print("media \(text)")
                    links.append(text)
                    //                    } else { // normal url
                    //                        print("url \(text)")
                    //                    }
                }
            }
        }
        catch {
            
        }
        return links
    }
    
    class func ExtractContent (content: String) -> String {
        var returnedContent = ""
        let content = fixPTags(string: content)
        
        
        do {
            let doc = try HTML(html: content, encoding: .utf8)
            returnedContent += "\(doc.text!)"
        }
        catch {
            returnedContent = content
        }
//        if let doc = HTML(html: content, encoding: .utf8) {
//            returnedContent += "\(doc.text!)"
////            for p in doc.css("p") {
////                returnedContent += "\(p.text!) \n"
////            }
////            if returnedContent.isEmpty {
////                for a in doc.css("a") {
////                    returnedContent += "\(a.text!) \n"
////                }
////            }
////
//        } else {
//            returnedContent = content
//        }
        return returnedContent
    }
    
    class func EscapeString (string: String) -> String {
        if let string = string.removingPercentEncoding {
            return string.replacingOccurrences(of: "&apos;", with: "'")
        }
        return string.replacingOccurrences(of: "&apos;", with: "'")
    }
    
    class func TagsToContent (string: String) -> String {
        return fixPTags(string: string)
    }
    
    class func FollowButtonStyling (button: UIButton, following: Bool) {
        let buttonBackground = UIColor.white
        let buttonForeground = #colorLiteral(red: 0.26, green: 0.47, blue: 0.96, alpha: 1)

        DispatchQueue.main.async(execute: {
            if (following) {
                button.backgroundColor = buttonForeground
                button.setTitleColor(buttonBackground, for: .normal)
                button.setTitle("Following", for: .normal)
            } else {
                button.backgroundColor = buttonBackground
                button.setTitleColor(buttonForeground, for: .normal)
                button.setTitle("Follow", for: .normal)
            }
        })
    }
    
    class func createAlert(controller: UIViewController
        , title: String, message: String, preferredStyle: UIAlertControllerStyle) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
            alert.addAction(UIAlertAction(title: "OK", style:UIAlertActionStyle.default, handler: nil))
            controller.present(alert, animated: true, completion: nil)
        }
    }
    
    private class func fixPTags(string: String) -> String {
        var newString = string.replacingOccurrences(of: "</p><p>", with: "\n")
        newString = newString.replacingOccurrences(of: "<br>", with: "\n")
        newString = newString.replacingOccurrences(of: "<br />", with: "\n")
        return newString.replacingOccurrences(of: "<p>", with: "").replacingOccurrences(of: "</p>", with: "")
    }
}
