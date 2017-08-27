//
//  Users.swift
//  Lit
//
//  Created by Chandan Brown on 7/24/16.
//  Copyright © 2016 Gaming Recess. All rights reserved.
//

import UIKit

// This is the information that pertains to each user
class User: NSObject {
    var profileImageUrl : String?
    var email : String?
    var name  : String?
    var id    : String?
    var appId : String?
    
    init(dictionary: [String: AnyObject]) {
        super.init()
        
        profileImageUrl = dictionary["profileImageUrl"] as? String
        email = dictionary["email"] as? String
        name  = dictionary["name"] as? String
        id    = dictionary["id"] as? String
        appId = dictionary["appId"] as? String
    
    }
}

enum UserEnum {
    case hasApp
    case noApp
}
