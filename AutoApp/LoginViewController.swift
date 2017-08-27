//
//  LoginViewController.swift
//  AutoApp
//
//  Created by Chandan Brown on 8/23/17.
//  Copyright © 2017 Chandan B. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    var viewController: UpdateFeedViewController?
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var loginEmailTextField: UITextField!
    @IBOutlet weak var loginPasswordTextField: UITextField!
    
    
    func handleLogin() {
        guard let email = loginEmailTextField.text, let password = loginPasswordTextField.text else {
            print("Form is not valid")
            return
        }
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            
            if error != nil {
                print (error as Any)
                return
            }
            
            //successfully logged in our user
            //Transition to next view
            self.setupProfile()
        })
    }
    
    func setupProfile() {
        viewController?.viewDidLoad()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func loginButton(_ sender: Any) {
        handleLogin()
    }
    
    @IBAction func createAccountButton(_ sender: Any) {
        handleRegister()
    }
    
    
    @IBAction func changeProfileImage(_ sender: Any) {
        handleSelectProfileImageView()
    }
    
    @IBOutlet weak var chooseProfileImage: UIButton!
    
}

extension LoginViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func handleRegister() {
        FIRDatabase.database().reference().child("usernames").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            
            let userName = self.nameTextField.text
            
            if currentData.value == nil {
                currentData.value = userName
            } else {
                self.nameTextField.text = userName
            }
            
            currentData.value = userName
            self.nameTextField.text = currentData.value as! String?
            return FIRTransactionResult.success(withValue: currentData)
            
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
        guard
            let password = passwordTextField.text,
            let name  = nameTextField.text,
            let email = emailTextField.text
            else {
                print("Form is not valid")
                return
        }
        
        if name == "" {
            print (name)
        } else {
            
            FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user: FIRUser?, error) in
                
                if error != nil {
                    print(error as Any)
                    return
                }
                
                guard let uid = user?.uid else {
                    return
                }
                
                //successfully authenticated user
                let imageName = NSUUID().uuidString
                let storageRef = FIRStorage.storage().reference().child("profile_images").child("\(imageName).jpg")
                
                if let profileImage = self.profileImageView.image, let uploadData = UIImageJPEGRepresentation(profileImage, 0.1) {
                    
                    storageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
                        
                        if error != nil {
                            print(error as Any)
                            return
                        }
                        
                        if let profileImageUrl = metadata?.downloadURL()?.absoluteString {
                            
                            let values = ["name": name, "email": email, "profileImageUrl": profileImageUrl]
                            
                            self.registerUserIntoDatabaseWithUID(uid: uid, values: values as [String : AnyObject])
                        }
                    })
                }
            })
        }
    }
    
    private func registerUserIntoDatabaseWithUID(uid: String, values: [String: AnyObject]) {
        let ref = FIRDatabase.database().reference()
        let usersReference = ref.child("users").child(uid)
        
        usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            
            if err != nil {
                print(err as Any)
                return
            }
            
            let dictionary = values
            let user = User(dictionary: dictionary)
            let username = FIRDatabase.database().reference().child("usernames")
            let values = [user.name!: uid]
            username.updateChildValues(values)
            self.setupProfile()
        })
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
        
        profilePicUpdate()
        
        dismiss(animated: true, completion: nil)
    }
    
    func profilePicUpdate() {
        let user = FIRAuth.auth()?.currentUser
        guard (user?.uid) != nil else {
            return
        }
        //successfully authenticated user
        let imageName = UUID().uuidString
        let storageRef = FIRStorage.storage().reference().child("profile_images").child("\(imageName).jpg")
        let metadata = FIRStorageMetadata()
        if let profileImage = self.profileImageView.image, let uploadData = UIImageJPEGRepresentation(profileImage, 0.1) {
            
            
            storageRef.put(uploadData, metadata: metadata, completion: { (metadata, error) in
                
                if error != nil {
                    print(error as Any)
                    return
                }
                
                if let profileImageUrl = metadata?.downloadURL()?.absoluteString {
                    
                    let values = ["profileImageUrl": profileImageUrl]
                    self.registerUserIntoDatabaseWithUID(uid: (user?.uid)!, values: values as [String : AnyObject])
                }
            })
        }
    }
    
    func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("canceled picker")
        dismiss(animated: true, completion: nil)
    }
}
