//
//  App.swift
//  AutoApp
//
//  Created by Chandan Brown on 8/26/17.
//  Copyright © 2017 Chandan B. All rights reserved.
//

import UIKit

// This is the information that pertains to each user
class App: NSObject {
    var owner : String?
    var name  : String?
    var id    : String?
    var goalCount : String?
    var completedGoals: String?
    
    init(dictionary: [String: AnyObject]) {
        super.init()
        owner = dictionary["owner"] as? String
        name    = dictionary["name"]    as? String
        id      = dictionary["id"]      as? String
        goalCount      = dictionary["goalCount"]      as? String
        completedGoals = dictionary["completedGoals"] as? String
    }
    
}
