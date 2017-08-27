//
//  UpdateViewController.swift
//  AutoApp
//
//  Created by Chandan Brown on 8/26/17.
//  Copyright © 2017 Chandan B. All rights reserved.
//

import UIKit
import Firebase

class UpdateViewController: UIViewController {

    @IBOutlet weak var inputContainerView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func pushUpdate(_ sender: Any) {
        handleSend()
    }
    
    var app: App? {
        didSet {
            navigationItem.title = app?.name
        }
    }
    
    func handleSend() {
        let properties = ["text": inputContainerView?.text]
        sendUpdateWithProperties(properties as [String : AnyObject])
    }
    
    fileprivate func sendUpdateWithProperties(_ properties: [String: AnyObject]) {
        let ref = FIRDatabase.database().reference().child("updates")
        let childRef = ref.childByAutoId()
        let toId = app!.id!
        let fromId = FIRAuth.auth()!.currentUser!.uid
        let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
        
        var values: [String: AnyObject] = ["toId": toId as AnyObject, "fromId": fromId as AnyObject, "timestamp": timestamp]
        
        //append properties dictionary onto values somehow??
        //key $0, value $1
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error as Any)
                return
            }
            
            self.inputContainerView?.text = nil
            
            let userupdatesRef = FIRDatabase.database().reference().child("user-updates").child(fromId).child(toId)
            
            let updateId = childRef.key
            userupdatesRef.updateChildValues([updateId: 1])
            
            let recipientUserupdatesRef = FIRDatabase.database().reference().child("user-updates").child(toId).child(fromId)
            recipientUserupdatesRef.updateChildValues([updateId: 1])
        }
    }

}
