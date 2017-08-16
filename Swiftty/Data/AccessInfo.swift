//
//  AccessInfo.swift
//  Swiftty
//
//  Created by Calv Collins on 30/07/2017.
//  Copyright © 2017 Calv Collins. All rights reserved.
//

import Foundation
import os.log

class AccessInfo: NSObject, NSCoding {
    
    var accessToken: String
    var url: String
    var user: String
    
    struct PropertyKey {
        static let accessToken = "access_token"
        static let url = "url"
        static let user = "user"
    }
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("access_info")
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(accessToken, forKey: PropertyKey.accessToken)
        aCoder.encode(url, forKey: PropertyKey.url)
        aCoder.encode(user, forKey: PropertyKey.user)
    }
    
    class func saveAccessInfo(info: AccessInfo) {
        let isSuccessful = NSKeyedArchiver.archiveRootObject(info, toFile: AccessInfo.ArchiveURL.path)
        if isSuccessful {
            print("saved")
        } else {
            print("save fucked")
        }
    }
    
    class func loadAccessInfo() -> AccessInfo? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: AccessInfo.ArchiveURL.path) as? AccessInfo
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let accessToken = aDecoder.decodeObject(forKey: PropertyKey.accessToken) as? String else {
            os_log("Unable to decode access token", log: OSLog.default, type: .debug)
            return nil
        }
        guard let url = aDecoder.decodeObject(forKey: PropertyKey.url) as? String else {
            os_log("Unable to decode url", log: OSLog.default, type: .debug)
            return nil
        }
        guard let user = aDecoder.decodeObject(forKey: PropertyKey.user) as? String else {
            os_log("Unable to decode user", log: OSLog.default, type: .debug)
            return nil
        }
        
        self.init(accessToken: accessToken, url: url, user: user)
    }
    
    init?(accessToken: String, url: String, user: String) {
        
        if accessToken.isEmpty || url.isEmpty || user.isEmpty {
            return nil
        }
        
        self.accessToken = accessToken
        self.url = url
        self.user = user
    }
}
