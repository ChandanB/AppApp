//
//  UpdateCard.swift
//  AutoApp
//
//  Created by Chandan Brown on 8/23/17.
//  Copyright © 2017 Chandan B. All rights reserved.
//


import Firebase
import UIKit

// This is a card created when aa developer updates an app

class Update: NSObject {
    var timestamp : NSNumber?
    var fromId    : String?
    var name      : String?
    var text      : String?
    var toId      : String?
    
    init(dictionary: [String: AnyObject]) {
        super.init()
        timestamp = dictionary["timestamp"] as? NSNumber
        fromId    = dictionary["fromId"]    as? String
        text      = dictionary["text"]      as? String
        toId      = dictionary["toId"]      as? String
    }
    
    func updatePartnerId() -> String? {
        return fromId == FIRAuth.auth()?.currentUser?.uid ? toId : fromId
    }
}

