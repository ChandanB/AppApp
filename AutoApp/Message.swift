//
//  Message.swift
//  Lit
//
//  Created by Chandan Brown on 7/24/16.
//  Copyright © 2016 Gaming Recess. All rights reserved.
//
//  It's Lit
//

import UIKit
import Firebase

class Message: NSObject {
    
    var imageHeight : NSNumber?
    var imageWidth  : NSNumber?
    var imageUrl    : String?
    
    var timestamp : NSNumber?
    var fromId    : String?
    var name      : String?
    var text      : String?
    var toId      : String?

    var videoUrl : String?
    
    init(dictionary: [String: AnyObject]) {
        super.init()
        
        imageHeight = dictionary["imageHeight"] as? NSNumber
        imageWidth  = dictionary["imageWidth"]  as? NSNumber
        imageUrl    = dictionary["imageUrl"]    as? String
        
        timestamp = dictionary["timestamp"] as? NSNumber
        fromId    = dictionary["fromId"]    as? String
        text      = dictionary["text"]      as? String
        toId      = dictionary["toId"]      as? String
        
        videoUrl = dictionary["videoUrl"] as? String
    }
    
    func chatPartnerId() -> String? {
        return fromId == FIRAuth.auth()?.currentUser?.uid ? toId : fromId
    }
}
