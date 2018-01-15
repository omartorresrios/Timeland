//
//  MyProfileController.swift
//  ReputationApp
//
//  Created by Omar Torres on 25/10/17.
//  Copyright © 2017 OmarTorres. All rights reserved.
//

import UIKit
import Locksmith
import Alamofire

class MyProfileController: UIViewController {
    
    var userSelected: User! = nil
    var userDictionary = [String: Any]()
    
    let storiesOptionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .black
        button.tintColor = .white
        button.setTitle("Momentos", for: .normal)
        button.addTarget(self, action: #selector(showUserStoriesView), for: .touchUpInside)
        button.layer.cornerRadius = 25
        return button
    }()
    
    let reviewsOptionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .black
        button.tintColor = .white
        button.setTitle("Reseñas", for: .normal)
        button.addTarget(self, action: #selector(showUserReviewsView), for: .touchUpInside)
        button.layer.cornerRadius = 25
        return button
    }()
    
    let fullnameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    let gearIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "gear").withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .black
        return imageView
    }()
    
    func showUserReviewsView() {
        let userReviewsController = UserReviewsController(collectionViewLayout: UICollectionViewFlowLayout())
        
        userReviewsController.userId = userSelected.id
        userReviewsController.userFullname = userSelected.fullname
        userReviewsController.userImageUrl = userSelected.profileImageUrl
        
        present(userReviewsController, animated: true, completion: nil)
    }
    
    func showUserStoriesView() {
        let userStoriesController = UserStoriesController(collectionViewLayout: UICollectionViewFlowLayout())
        
        userStoriesController.userId = userSelected.id
        userStoriesController.userFullname = userSelected.fullname
        userStoriesController.userImageUrl = userSelected.profileImageUrl
        
        present(userStoriesController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        navigationController?.navigationBar.isHidden = true
        
        setupUserInfo()
        
        setupTopViews()
        
        setupOptionsButtons()
        
    }
    
    func setupUserInfo() {
        guard let userName = Locksmith.loadDataForUserAccount(userAccount: "currentUserName") else { return }
        guard let userId = Locksmith.loadDataForUserAccount(userAccount: "currentUserId") else { return }
        guard let userUsername = Locksmith.loadDataForUserAccount(userAccount: "currentUsernameName") else { return }
        guard let userAvatar = Locksmith.loadDataForUserAccount(userAccount: "currentAvatar") else { return }
        
        fullnameLabel.text = (userName as [String : AnyObject])["name"] as! String?
        
        userDictionary.updateValue((userId as [String : AnyObject])["id"] as! Int!, forKey: "id")
        userDictionary.updateValue((userName as [String : AnyObject])["name"] as! String!, forKey: "fullname")
        userDictionary.updateValue((userUsername as [String : AnyObject])["username"] as! String!, forKey: "username")
        userDictionary.updateValue((userAvatar as [String : AnyObject])["userAvatar"] as! String!, forKey: "avatarUrl")
        
        let user = User(uid: (userId as [String : AnyObject])["id"] as! Int!, dictionary: userDictionary)
        
        userSelected = user
    }
    
    func setupTopViews() {
        view.addSubview(gearIcon)
        gearIcon.anchor(top: view.topAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 25, height: 25)
        gearIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSheetAction)))
        gearIcon.isUserInteractionEnabled = true
        
        view.addSubview(fullnameLabel)
        fullnameLabel.anchor(top: gearIcon.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 15, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
    }
    
    fileprivate func setupOptionsButtons() {
        let stackView = UIStackView(arrangedSubviews: [storiesOptionButton, reviewsOptionButton])
        
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        
        view.addSubview(stackView)
        stackView.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 50)
        stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
    }
    
    func handleSheetAction() {
        let actionSheetController = UIAlertController()
        
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            
        }
        actionSheetController.addAction(cancelActionButton)
        
        let saveActionButton = UIAlertAction(title: "Cerrar sesión", style: .default) { (action) in
            self.handleLogout()
        }
        actionSheetController.addAction(saveActionButton)
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    func handleLogout() {
        clearLoggedinFlagInUserDefaults()
        clearAPITokensFromKeyChain()
        
        DispatchQueue.main.async {
            let loginController = LoginController()
            let navController = UINavigationController(rootViewController: loginController)
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    func clearLoggedinFlagInUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "userLoggedIn")
        defaults.synchronize()
    }
    
    func clearAPITokensFromKeyChain() {
        // clear API Auth Token
        try! Locksmith.deleteDataForUserAccount(userAccount: "AuthToken")
        try! Locksmith.deleteDataForUserAccount(userAccount: "currentUserId")
        try! Locksmith.deleteDataForUserAccount(userAccount: "currentUserName")
    }
}
