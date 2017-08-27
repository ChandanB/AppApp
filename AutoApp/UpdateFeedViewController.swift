//
//  updateFeedViewController.swift
//  AutoApp
//
//  Created by Chandan Brown on 8/19/17.
//  Copyright © 2017 Chandan B. All rights reserved.
//

import UIKit
import Firebase

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

class UpdateFeedViewController: UIViewController {
    
    // Setup user
    var user = User(dictionary: [:])
    var hasApp: UserEnum?
    
    // Setup app
    var app = App(dictionary: [:])
    
    // Setup updates
    var updates = [Update]()
    var updatesDictionary = [String: Update]()
    
    // Sets up "nib" for cell to be used on controller
    let nib = UINib(nibName: String(describing: CollectionViewCell.self), bundle: nil)
    
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    var startingImageView: UIImageView?
    
    var timer: Timer?
    
    //Outlets for controller
    
    
    @IBOutlet weak var appName: UILabel!
    @IBOutlet weak var goalsCompletedLabel: UILabel!
    @IBOutlet var goalsCompletedBar: UIProgressView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet var updateCollectionView: UICollectionView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hasApp = UserEnum.noApp
        
        self.navigationController?.navigationBar.barTintColor = .black
        
        let textAttributes = [NSForegroundColorAttributeName:UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        let settingsImage = UIImage(named: "settings")
        let messagesImage = UIImage(named: "Messaging Image Shape")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: messagesImage, style: .plain, target: self, action: #selector(goToMessages))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: settingsImage, style: .plain, target: self, action: #selector(handleMore))
        
        self.navigationItem.rightBarButtonItem?.tintColor = .white
        self.navigationItem.leftBarButtonItem?.tintColor = .white
        setupCollectionView()
        checkIfUserIsLoggedIn()
        print ("Updates: \(updates)")
    }
    
    lazy var settingsLauncher: SettingsLauncher = {
        let launcher = SettingsLauncher()
        launcher.homeController = self
        return launcher
    }()
    
    func handleMore() {
        //show menu
        settingsLauncher.showSettings()
    }
    
    func logOut() {
        do {
            try FIRAuth.auth()?.signOut()
        } catch let logoutError {
            print(logoutError)
        }
        checkIfUserIsLoggedIn()
    }
    
    func goToMessages() {
        let vc = MessagesTableViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func fetchUserAndSetupPage() {
        let imageView = UIImageView()
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        FIRDatabase.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                self.navigationItem.title = dictionary["name"] as? String
                self.user = User(dictionary: dictionary)
                self.setupUser()
            }
        }, withCancel: nil)
    }
    
    func fetchAppAndSetupCollectionView() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        let ref = FIRDatabase.database().reference()
        
        ref.child("users").child(uid).child("appId").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                let path = snapshot.value!
                ref.child("apps").child("apps").child("\(path)").observeSingleEvent(of: .value, with: { (snapshot) in
                    if let dictionary = snapshot.value as? [String: AnyObject] {
                        self.hasApp = UserEnum.hasApp
                        self.appName.text = dictionary["name"] as? String
                        
                        if (dictionary["goalCount"] as? String) != nil {
                            self.goalsCompletedLabel.text = "19/" + "\(dictionary["goalCount"] as? String ?? "0")" + " Goals Completed"
                            
                            //Divide GoalCount by GoalsCompleted then divide 100 by outcome
                            
                            let num = dictionary["goalCount"] as? String ?? "0"
                            let newNum = Float(num)!
                            print (newNum)
                            
                            let a = (newNum / 19)
                            let b = 100 / a
                            let c = b * 0.01
                            
                            let bar = self.goalsCompletedBar
                            bar?.progress = c
                            
                            if bar?.progress > 0.5 {
                                bar?.progressTintColor = UIColor(r: 255, g: 203, b: 100)
                            } else if bar?.progress == 1.0 {
                                bar?.progressTintColor = .green
                            }
                        }
                        
                        self.app = App(dictionary: dictionary)
                        self.observeUserUpdates()
                    }
                }, withCancel: nil)
            }
            
        }, withCancel: nil)
    }
    
    func setupUser() {
        if let profileImageUrl = user.profileImageUrl {
            profileImageView.loadImageUsingCacheWithUrlString(profileImageUrl)
        }
    }
    
    func checkIfUserIsLoggedIn() {
        // If user is logged in
        if FIRAuth.auth()?.currentUser == nil {
            OperationQueue.main.addOperation {
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyBoard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                vc.viewController = self
                self.present(vc, animated: true, completion: nil)
            }
        } else {
            fetchUserAndSetupPage()
            fetchAppAndSetupCollectionView()
        }
    }
    
    func showControllerForSetting(_ setting: Setting) {
        if setting.name.rawValue == "Shop" {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyBoard.instantiateViewController(withIdentifier: "ShoppingController")
            self.navigationController?.pushViewController(vc, animated: true)
        } else if setting.name.rawValue == "Sign Out" {
            logOut()
        } else {
            let dummySettingsViewController = UIViewController()
            dummySettingsViewController.view.backgroundColor = UIColor.white
            dummySettingsViewController.navigationItem.title = setting.name.rawValue
            navigationController?.navigationBar.tintColor = UIColor.white
            navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
            navigationController?.pushViewController(dummySettingsViewController, animated: true)
        }
    }
}

extension UpdateFeedViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    
    func setupCollectionView() {
        if updateCollectionView != nil {
            updateCollectionView.delegate = self
            updateCollectionView.dataSource = self
            updateCollectionView.register(nib, forCellWithReuseIdentifier: "updateCell")
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return updates.count
    }
    
    fileprivate func fetchUpdateWithUpdateId(_ updateId: String) {
        let updatesReference = FIRDatabase.database().reference().child("updates").child(updateId)
    
        updatesReference.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                
                let update = Update(dictionary: dictionary)

                if let updatePartnerId = update.updatePartnerId() {
                    print ("Updates Dictionary updated")
                    self.updatesDictionary[updatePartnerId] = update
                    self.updates.append(update)
                }
                
                print(self.updates.count)
                
                self.attemptReloadOfTable()
            }
        }, withCancel: nil)
    }
    
    fileprivate func attemptReloadOfTable() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
    func handleReloadTable() {
     //   self.updates = Array(self.updatesDictionary.values)
       self.updates.sort(by: { (update1, update2) -> Bool in
            return update1.timestamp?.int32Value > update2.timestamp?.int32Value
       })
        
        DispatchQueue.main.async(execute: {
            self.updateCollectionView.reloadData()
        })
    }
    
    func observeUserUpdates() {
        guard let uid = app.id else {
            return
        }
   
        let ref = FIRDatabase.database().reference().child("user-updates").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            for child in snapshot.children {
                let snap = child as! FIRDataSnapshot
                let updateId = snap.key
                self.fetchUpdateWithUpdateId(updateId)
            }
        }, withCancel: nil)
        
        ref.observe(.childRemoved, with: { (snapshot) in
            print(snapshot.key)
            
            self.updatesDictionary.removeValue(forKey: snapshot.key)
            self.attemptReloadOfTable()
            
        }, withCancel: nil)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "updateCell", for: indexPath) as! CollectionViewCell
        
        let row = indexPath.row
        
        let update = updates[(indexPath as NSIndexPath).row]
        cell.update = update
        
        return cell
    }
    
}

extension UpdateFeedViewController {
    
    func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
        present(picker, animated: true, completion: nil)
    }
    
    func dismissFullscreenImage(sender: UITapGestureRecognizer) {
        navigationController?.isNavigationBarHidden = false
        sender.view?.removeFromSuperview()
    }
    
    func imageTapped(sender: UITapGestureRecognizer) {
        let imageView = sender.view as! UIImageView
        performZoomInForStartingImageView(imageView)
    }
    
    //my custom zooming logic
    func performZoomInForStartingImageView(_ startingImageView: UIImageView) {
        
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.backgroundColor = .clear
        zoomingImageView.image = startingImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            
            blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = .clear
            blackBackgroundView?.alpha = 1
            blackBackgroundView?.addBlurEffect()
            keyWindow.addSubview(blackBackgroundView!)
            
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.blackBackgroundView?.alpha = 1
                
                // h2 / w1 = h1 / w1
                // h2 = h1 / w1 * w1
                let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingImageView.center = keyWindow.center
                
                
            }, completion: { (completed) in
            })
        }
    }
    
    func handleZoomOut(_ tapGesture: UITapGestureRecognizer) {
        if let zoomOutImageView = tapGesture.view {
            //need to animate back out to controller
            zoomOutImageView.layer.cornerRadius = 65
            zoomOutImageView.clipsToBounds = true
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackgroundView?.alpha = 0
                
            }, completion: { (completed) in
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            })
        }
    }
}
