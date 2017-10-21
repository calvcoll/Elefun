//
//  StatusStore.swift
//  Elefun
//
//  Created by Calv Collins on 14/08/2017.
//  Copyright © 2017 Calv Collins. All rights reserved.
//

import UIKit
import MastodonKit

class StatusStore: NSObject, NSCoding {
    var statuses: [Status]
    var lastStatus: Status
    
    private struct PropertyKey {
        static let statuses = "statuses"
        static let lastStatus = "lastStatus"
    }
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("status_store")
    
    func encode(with aCoder: NSCoder) {
//        aCoder.encode(statuses, forKey: PropertyKey.statuses)
//        aCoder.encode(lastStatus, forKey: PropertyKey.lastStatus)
    }
    
    class func saveStatuses(info: StatusStore) {
        let isSuccessful = NSKeyedArchiver.archiveRootObject(info, toFile: StatusStore.ArchiveURL.path)
        if isSuccessful {
            print("saved")
        } else {
            print("save fucked")
        }
    }
    
    class func loadStatuses() -> StatusStore? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: StatusStore.ArchiveURL.path) as? StatusStore
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let statuses = aDecoder.decodeObject(forKey: PropertyKey.statuses) as? [Status] else {
            return nil
        }
        guard let lastStatus = aDecoder.decodeObject(forKey: PropertyKey.lastStatus) as? Status else {
            return nil
        }
        self.init(statuses: statuses, lastStatus: lastStatus)
    }
    
    init?(statuses: [Status], lastStatus: Status) {
        
        if statuses.isEmpty { // || lastStatus != nil
            return nil
        }
        
        self.statuses = statuses
        self.lastStatus = lastStatus
    }
}
