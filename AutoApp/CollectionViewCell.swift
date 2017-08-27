//
//  CollectionViewCell.swift
//  AutoApp
//
//  Created by Chandan Brown on 8/19/17.
//  Copyright © 2017 Chandan B. All rights reserved.
//

import UIKit
import Firebase

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var updaterName: UILabel!
    @IBOutlet weak var updateTimeLabel: UILabel!
    
    @IBOutlet weak var updateDescLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func likeUpdate(_ sender: Any) {
        print("Update Liked")
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        print("Send Message")
        goToMessages()
    }
    
    func goToMessages() {
        let ref = FIRDatabase.database().reference().child("users").child((update?.fromId)!)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                print(snapshot.value)
                var user: User
                user = User(dictionary: dictionary)
                user.setValuesForKeys(dictionary)
                let layout = UICollectionViewFlowLayout()
                let vc = ChatLogController(collectionViewLayout: layout)
                let navController = UINavigationController(rootViewController: vc)
                user.id = self.update?.fromId
                vc.user = user
                self.window?.rootViewController?.present(navController, animated: true, completion: nil)
            }
        }, withCancel: nil)
    }
    
    var update: Update? {
        didSet {
            setupName()
            updateDescLabel?.text = update?.text
            if let seconds = update?.timestamp?.doubleValue {
                let timestampDate = Date(timeIntervalSince1970: seconds)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM dd"
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = " hh:mm a"
                
                updateTimeLabel.text = dateFormatter.string(from: timestampDate) + " at" + timeFormatter.string(from: timestampDate)
            }
        }
    }
    
    fileprivate func setupName() {
        let ref = FIRDatabase.database().reference().child("users").child((update?.fromId)!).child("name")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value
            self.updaterName?.text = value as? String
            self.updaterName?.textColor = .black
        }, withCancel: nil)
        
    }
}
