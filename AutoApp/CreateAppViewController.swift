//
//  CreateAppViewController.swift
//  AutoApp
//
//  Created by Chandan Brown on 8/26/17.
//  Copyright © 2017 Chandan B. All rights reserved.
//

import UIKit
import Firebase

class CreateAppViewController: UIViewController {
    
    @IBOutlet weak var appNameTextField: UITextField!
    @IBOutlet weak var goalCountTextField: UITextField!
    var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func createAppButton(_ sender: Any) {
        handleRegister()
    }
    
    func handleRegister() {
        let name = appNameTextField.text
        let goalCount = goalCountTextField.text
        let user = FIRAuth.auth()?.currentUser
        
        let ref = FIRDatabase.database().reference()
        let usersReference = ref.child("users").child((user?.uid)!)
        let appsReference = ref.child("apps")
        let newRef = appsReference.child("apps").childByAutoId()
        let appId = newRef.key
        
        let userValues = ["appId": appId]
        usersReference.updateChildValues(userValues)
        
        let values = ["name": name, "goalCount": goalCount, "owner": user?.uid, "id": appId]
        newRef.setValue(values)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
