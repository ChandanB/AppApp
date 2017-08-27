//
//  DevAppsTableViewController.swift
//  AutoApp
//
//  Created by Chandan Brown on 8/26/17.
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

class DevAppsTableViewController: UITableViewController, UISearchControllerDelegate {
    
    // Search
    let searchController = UISearchController(searchResultsController: nil)
    lazy var searchBar : UISearchBar = UISearchBar()
    var searchActive   : Bool = false
    
    // Index
    var cellIndexPath: IndexPath!
    var location = CGPoint.zero
    
    // Instance
    var updateViewController : UpdateViewController?
    
    // Data to go in cells
    var updatesDictionary = [String: Update]()
    var updates = [Update]()
    var filtered = [App]()
    var currentUser: User?
    let cellId = "updateCell"
    var apps  = [App]()
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(handleCancel))
        navigationItem.leftBarButtonItem?.tintColor = .white
        navigationItem.title = "Apps"
        let textAttributes = [NSForegroundColorAttributeName:UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        
        tableView.tableHeaderView = searchController.searchBar
        definesPresentationContext = true
        
        let searchBarForView = searchController.searchBar
        searchBarForView.tintColor = .red
        searchBarForView.searchBarStyle = UISearchBarStyle.minimal
        searchBarForView.placeholder = "Search"
        searchBarForView.barTintColor = .black
        searchBarForView.isTranslucent = true
        searchBarForView.delegate = self
        searchBarForView.sizeToFit()
        
        let textField = searchBarForView.value(forKey: "searchField") as? UITextField
        textField?.textColor = .black
        
        fetchapp()
        observeAppUpdates()
        
        self.view.backgroundColor = .white
        self.tableView.backgroundView = nil
        self.tableView.backgroundView = UIView()
        self.tableView.backgroundView?.backgroundColor = .white
        
        tableView.register(UpdateCell.self, forCellReuseIdentifier: cellId)
        tableView.allowsMultipleSelectionDuringEditing = true
        
        if let splitViewController = splitViewController {
            let controllers = splitViewController.viewControllers
            updateViewController = ((controllers[controllers.count-1] as! UINavigationController).topViewController as? UpdateViewController?)!
        }
    }
    
    fileprivate func fetchUpdateWithUpdateId(_ updateId: String) {
        let updatesReference = FIRDatabase.database().reference().child("updates").child(updateId)
        updatesReference.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let update = Update(dictionary: dictionary)
                
                if let chatPartnerId = update.updatePartnerId() {
                    self.updatesDictionary[chatPartnerId] = update
                }
                self.attemptReloadOfTable()
            }
        }, withCancel: nil)
    }
    
    fileprivate func attemptReloadOfTable() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
    func observeAppUpdates() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        let ref = FIRDatabase.database().reference().child("app-updates").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            
            let appId = snapshot.key
            FIRDatabase.database().reference().child("app-updates").child(uid).child(appId).observe(.childAdded, with: { (snapshot) in
                
                let updateId = snapshot.key
                self.fetchUpdateWithUpdateId(updateId)
                
            }, withCancel: nil)
            
        }, withCancel: nil)
        
        ref.observe(.childRemoved, with: { (snapshot) in
            print(snapshot.key)
            
            self.updatesDictionary.removeValue(forKey: snapshot.key)
            self.attemptReloadOfTable()
            
        }, withCancel: nil)
        
    }
    
    func fetchapp() {
        FIRDatabase.database().reference().child("apps").child("apps").observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let app = App(dictionary: dictionary)
                app.id = snapshot.key
                self.apps.append(app)
                
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
            }
        }, withCancel: nil)
    }
    
    func handleReloadTable() {
        self.updates = Array(self.updatesDictionary.values)
        self.updates.sort(by: { (update1, update2) -> Bool in
            return update1.timestamp?.int32Value > update2.timestamp?.int32Value
        })
        
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }
    
    func showUpdateControllerForApp(_ app: App) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "UpdateViewController") as! UpdateViewController
        vc.app = app
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true, completion: nil)
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filtered = apps.filter({( app : App) -> Bool in
            let categoryMatch = (scope == "All") || (app.name == scope)
            return categoryMatch
        })
        self.attemptReloadOfTable()
    }
    
    func handleCancel() {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UpdateCell
        var app = apps[(indexPath as NSIndexPath).row]
        
        if searchController.isActive && searchController.searchBar.text != "" {
            app = filtered[(indexPath as NSIndexPath).row]
            cell.textLabel?.text = app.name
            cell.timeLabel.text = ""
            cell.update = nil
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let app = apps[(indexPath as NSIndexPath).row]
        
        guard let chatPartnerId = app.id else {
            return
        }
        
        let ref = FIRDatabase.database().reference().child("apps").child("apps").child(chatPartnerId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String: AnyObject] else {
                return
            }
            
            let app = App(dictionary: dictionary)
            app.id = chatPartnerId
            self.showUpdateControllerForApp(app)
            
        }, withCancel: nil)
        
        if searchController.isActive && searchController.searchBar.text != ""  {
            var app: App
            app = self.filtered[(indexPath as NSIndexPath).row]
            self.showUpdateControllerForApp(app)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            
            if let indexPath = tableView.indexPathForSelectedRow {
                var app: App
                app = apps[(indexPath as NSIndexPath).row]
                if searchController.isActive && searchController.searchBar.text != "" {
                    app = filtered[(indexPath as NSIndexPath).row]
                }
                
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyBoard.instantiateViewController(withIdentifier: "UpdateViewController") as! UpdateViewController
                vc.app = app
                vc.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                vc.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != ""  {
            return filtered.count
        } else {
            return apps.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        let update = self.updates[(indexPath as NSIndexPath).row]
        if let chatPartnerId = update.updatePartnerId() {
            FIRDatabase.database().reference().child("app-updates").child(uid).child(chatPartnerId).removeValue(completionBlock: { (error, ref) in
                
                if error != nil {
                    print("Failed to delete update:", error as Any)
                    return
                }
                
                self.updatesDictionary.removeValue(forKey: chatPartnerId)
                self.attemptReloadOfTable()
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if searchController.isActive {
            return false
        } else {
            return true
        }
    }
}


extension DevAppsTableViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchText: searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
        self.attemptReloadOfTable()
    }
}

extension DevAppsTableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        // let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}

