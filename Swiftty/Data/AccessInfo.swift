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
    var authCode: String
    var url: String
    
    struct PropertyKey {
        static let accessToken = "access_token"
        static let authCode = "auth_code"
        static let url = "url"
    }
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("access_info")
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(accessToken, forKey: PropertyKey.accessToken)
        aCoder.encode(authCode, forKey: PropertyKey.authCode)
        aCoder.encode(url, forKey: PropertyKey.url)
    }
    
    class func saveAccessInfo(info: AccessInfo) {
        let isSuccessful = NSKeyedArchiver.archiveRootObject(info, toFile: AccessInfo.ArchiveURL.path)
        if isSuccessful {
            print("saved")
        } else {
            print("save failed")
        }
    }
    
    class func loadAccessInfo() -> AccessInfo? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: AccessInfo.ArchiveURL.path) as? AccessInfo
    }
    
    class func clearAccessInfo() -> Bool {
        do {
            try FileManager.default.removeItem(atPath: AccessInfo.ArchiveURL.path)
            return true
        } catch {
            return false
        }
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let accessToken = aDecoder.decodeObject(forKey: PropertyKey.accessToken) as? String else {
            os_log("Unable to decode access token", log: OSLog.default, type: .debug)
            return nil
        }
        guard let authCode = aDecoder.decodeObject(forKey: PropertyKey.authCode) as? String else {
            os_log("Unable to decode refresh token", log: OSLog.default, type: .debug)
            return nil
        }
        guard let url = aDecoder.decodeObject(forKey: PropertyKey.url) as? String else {
            os_log("Unable to decode url", log: OSLog.default, type: .debug)
            return nil
        }
        
        self.init(accessToken: accessToken, authCode: authCode, url: url)
    }
    
    init?(accessToken: String, authCode: String, url: String) {
        
        if accessToken.isEmpty || authCode.isEmpty || url.isEmpty {
            return nil
        }
        
        self.accessToken = accessToken
        self.authCode = authCode
        self.url = url
    }
}
