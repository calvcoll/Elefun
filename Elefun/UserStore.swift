//
//  UserStore.swift
//  Elefun
//
//  Created by Calv Collins on 22/10/2017.
//  Copyright © 2017 Calv Collins. All rights reserved.
//

import UIKit
import os.log

class UserStore: NSObject, NSCoding {
    
    var users: [AccessInfo]
    
    struct PropertyKey {
        static let users = "users"
    }
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("user_store")
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(users, forKey: PropertyKey.users)
    }
    
    class func saveUserStore(store: UserStore) {
        let isSuccessful = NSKeyedArchiver.archiveRootObject(store, toFile: UserStore.ArchiveURL.path)
        if isSuccessful {
            print("saved")
        } else {
            print("save failed")
        }
    }
    
    class func loadUserStore() -> UserStore? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: UserStore.ArchiveURL.path) as? UserStore
    }
    
    class func clearAccessInfo() -> Bool {
        do {
            try FileManager.default.removeItem(atPath: UserStore.ArchiveURL.path)
            return true
        } catch {
            return false
        }
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let users = aDecoder.decodeObject(forKey: PropertyKey.users) as? [AccessInfo]
            else {
                os_log("Unable to decode users", log: OSLog.default, type: .debug)
                return nil
        }
        
        self.init(users: users)
    }
    
    init?(users: [AccessInfo]) {
        
        if users.isEmpty {
            return nil
        }
        
        self.users = users
    }

}
