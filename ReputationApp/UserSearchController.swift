//
//  UserSearchController.swift
//  ReputationApp
//
//  Created by Omar Torres on 26/05/17.
//  Copyright © 2017 OmarTorres. All rights reserved.
//

import UIKit
import Alamofire
import Locksmith
import AVFoundation
//import googleapis

//let SAMPLE_RATE = 16000

class UserSearchController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate/*, AudioControllerDelegate*/ {
    
    let httpHelper = HTTPHelper()
    let cellId = "cellId"
    var filteredUsers = [User]()
    var users = [User]()
    var currentUserDic = [String: Any]()
    var collectionView: UICollectionView!
    var userSelected: User!
//    var audioData: NSMutableData!
    
    let loader: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        indicator.alpha = 1.0
        indicator.startAnimating()
        return indicator
    }()
    
    let messageLabel: UILabel = {
        let ml = UILabel()
        ml.font = UIFont.systemFont(ofSize: 12)
        ml.numberOfLines = 0
        ml.textAlignment = .center
        return ml
    }()
    
    let userInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    var tap = UITapGestureRecognizer()
    
    
//    let searchButton: UIButton = {
//        let button = UIButton()
//        button.setImage(#imageLiteral(resourceName: "record").withRenderingMode(.alwaysTemplate), for: .normal)
//        button.tintColor = .gray
//        button.addTarget(self, action: #selector(recordAudio(_:)), for: .touchUpInside)
//        return button
//    }()
//
//    let resultLabel: UILabel = {
//        let label = UILabel()
//        label.text = "HELLO 2018"
//        label.numberOfLines = 0
//        label.textColor = .white
//        return label
//    }()
//
//    let stopButton: UIButton = {
//        let button = UIButton()
//        button.setTitle("Otra búsqueda", for: .normal)
//        button.backgroundColor = .black
//        button.addTarget(self, action: #selector(stopAudio(_:)), for: .touchUpInside)
//        return button
//    }()
    
//    func wordForSearch(word: String) {
//        filteredUsers = self.users.filter { (user) -> Bool in
//            return user.fullname.lowercased().contains(word.lowercased())
//        }
//
//        // Check is there are results
//        if filteredUsers.isEmpty {
//            messageLabel.isHidden = false
//            messageLabel.text = "🙁 No encontramos a esa persona."
//            searchButton.tintColor = .gray
//            loader.stopAnimating()
//        } else {
//            messageLabel.isHidden = true
//        }
//
//        collectionView?.reloadData()
//    }
//
//    func processSampleData(_ data: Data) -> Void {
//
//        audioData.append(data)
//
//        // We recommend sending samples in 100ms chunks
//        let chunkSize : Int /* bytes/chunk */ = Int(0.1 /* seconds/chunk */
//            * Double(SAMPLE_RATE) /* samples/second */
//            * 2 /* bytes/sample */);
//
//        if (audioData.length > chunkSize) {
//
////            self.collectionView?.addSubview((self.loader))
////            self.loader.anchor(top: nil, left: nil, bottom: self.searchButton.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 40, height: 40)
////            self.loader.centerXAnchor.constraint(equalTo: (self.collectionView?.centerXAnchor)!).isActive = true
////            self.loader.isHidden = false
////            self.loader.startAnimating()
//
//            SpeechRecognitionService.sharedInstance.streamAudioData(audioData, completion: { [weak self] (response, error) in
//
//                guard let strongSelf = self else {
//                    return
//                }
//
//                if let error = error {
//                    strongSelf.resultLabel.text = error.localizedDescription
//                } else if let response = response {
//                    var finished = false
//                    print(response)
//                    for result in response.resultsArray! {
//                        if let result = result as? StreamingRecognitionResult {
//                            if result.isFinal {
//                                finished = true
//
////                                print("Terminó la búsqueda!")
////                                self?.loader.isHidden = true
////                                self?.loader.stopAnimating()
////                                self?.searchButton.tintColor = .gray
////                                _ = AudioController.sharedInstance.stop()
////                                SpeechRecognitionService.sharedInstance.stopStreaming()
//                            }
//
//                            for alternative in result.alternativesArray! {
//                                if let transcript = alternative as? SpeechRecognitionAlternative {
//                                    for word in transcript.wordsArray! {
//                                        if let word = word as? WordInfo {
//                                            strongSelf.resultLabel.text = word.word
//                                            self?.wordForSearch(word: word.word)
//
//
//                                        }
//                                    }
//
//                                }
//                            }
//                        }
//                    }
//
//                    if finished {
////                        strongSelf.stopAudio(strongSelf)
//                    }
//                }
//            })
//            self.audioData = NSMutableData()
//        }
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 90, height: 120)
        
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UserSearchCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.backgroundColor = .white
        self.view.addSubview(collectionView)
        
//        AudioController.sharedInstance.delegate = self
        
        // Reachability for checking internet connection
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityStatusChanged), name: NSNotification.Name(rawValue: "ReachStatusChanged"), object: nil)
        
        navigationController?.navigationBar.isHidden = true
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag
        
        
        //        let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout
        layout.sectionHeadersPinToVisibleBounds = true
        
        
        
        // Initialize the loader and position it
        collectionView.addSubview(loader)
        //        let indicatorYStartPosition = (navigationController?.navigationBar.frame.size.height)! + 10
        loader.center = CGPoint(x: UIScreen.main.bounds.size.width / 2, y: 40)
        
      
        
        // Position the messageLabel
        view.addSubview(messageLabel)
        messageLabel.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 0, height: 0)
        messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        // Initialize functions
        loadAllUsers()
        
        
//        searchButton.adjustsImageWhenHighlighted = false
        
        
//        view.addSubview(resultLabel)
//        resultLabel.anchor(top: view.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 45, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        //        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Log out", style: .plain, target: self, action: #selector(handleLogout))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // General properties of the view
        navigationController?.tabBarController?.tabBar.isHidden = false
        UIApplication.shared.isStatusBarHidden = true
        
    }
    
//    func recordAudio(_ sender: NSObject) {
////        messageLabel.isHidden = true
////        searchButton.tintColor = .red
//        let audioSession = AVAudioSession.sharedInstance()
//        do {
//            try audioSession.setCategory(AVAudioSessionCategoryRecord)
//        } catch {
////            print("Some error")
//        }
//        audioData = NSMutableData()
//        _ = AudioController.sharedInstance.prepare(specifiedSampleRate: SAMPLE_RATE)
//        SpeechRecognitionService.sharedInstance.sampleRate = SAMPLE_RATE
//        _ = AudioController.sharedInstance.start()
//
//        //        view.addSubview(stopButton)
//        //        stopButton.anchor(top: nil, left: nil, bottom: view.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 0, height: 50)
//        //        stopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//    }
//
//    func stopAudio(_ sender: NSObject) {
////        stopButton.isHidden = true
//        _ = AudioController.sharedInstance.stop()
//        SpeechRecognitionService.sharedInstance.stopStreaming()
//    }
    
//    func stopAudio() {
//        _ = AudioController.sharedInstance.stop()
//        SpeechRecognitionService.sharedInstance.stopStreaming()
//    }
    
    func reachabilityStatusChanged() {
        print("Checking connectivity...")
    }
    
    func showUserStoriesView() {
        
//        stopAudio()
        let userStoriesController = UserStoriesController(collectionViewLayout: UICollectionViewFlowLayout())
        
        userStoriesController.userId = userSelected.id
        userStoriesController.userFullname = userSelected.fullname
        userStoriesController.userImageUrl = userSelected.profileImageUrl
        userStoriesController.currentUserDic = currentUserDic
        
        present(userStoriesController, animated: true) {
            self.viewGeneral.removeFromSuperview()
        }
    }
    
    func showUserReviewsView() {
        
//                stopAudio()
                let userReviewsController = UserReviewsController(collectionViewLayout: UICollectionViewFlowLayout())
        
                userReviewsController.userId = userSelected.id
                userReviewsController.userFullname = userSelected.fullname
                userReviewsController.userImageUrl = userSelected.profileImageUrl
                userReviewsController.currentUserDic = currentUserDic
        
                present(userReviewsController, animated: true) {
                    self.viewGeneral.removeFromSuperview()
                }
    }
    
    func showWriteReviewView() {
        
//                stopAudio()
                let writeReviewController = WriteReviewController()
        
                writeReviewController.userId = userSelected.id
                writeReviewController.userFullname = userSelected.fullname
                writeReviewController.userImageUrl = userSelected.profileImageUrl
                writeReviewController.currentUserDic = currentUserDic
        
                present(writeReviewController, animated: true) {
                    self.viewGeneral.removeFromSuperview()
                }
    }
    
    func loadAllUsers() {
        // Check for internet connection
        if (reachability?.isReachable)! {
            
            // Retreieve Auth_Token from Keychain
            if let userToken = Locksmith.loadDataForUserAccount(userAccount: "AuthToken") {
                
                let authToken = userToken["authenticationToken"] as! String
                
                print("Token: \(userToken)")
                
                // Set Authorization header
                let header = ["Authorization": "Token token=\(authToken)"]
                
                print("THE HEADER: \(header)")
                
                Alamofire.request("https://protected-anchorage-18127.herokuapp.com/api/all_users", method: .get, parameters: nil, encoding: URLEncoding.default, headers: header).responseJSON { (response) in
                    switch response.result {
                    case .success(let JSON):
                        print("THE JSON: \(JSON)")
                        
                        let jsonArray = JSON as! NSDictionary
                        
                        let dataArray = jsonArray["users"] as! NSArray
                        
                        dataArray.forEach({ (value) in
                            guard let userDictionary = value as? [String: Any] else { return }
                            print("this is userDictionary: \(userDictionary)")
                            
                            guard let userIdFromKeyChain = Locksmith.loadDataForUserAccount(userAccount: "currentUserId") else { return }
                            
                            let userId = userIdFromKeyChain["id"] as! Int
                            
                            if userDictionary["id"] as! Int == userId {
                                print("Found myself, omit from list")
                                self.currentUserDic = userDictionary
                                return
                            }
                            let user = User(uid: userDictionary["id"] as! Int, dictionary: userDictionary)
                            self.users.append(user)
                            
                        })
                        
                        self.users.sort(by: { (u1, u2) -> Bool in
                            
                            return u1.fullname.compare(u2.fullname) == .orderedAscending
                            
                        })
                        
                        self.filteredUsers = self.users
                        self.collectionView.reloadData()
                        
//                        self.view.addSubview(self.searchButton)
//                        self.searchButton.anchor(top: nil, left: nil, bottom: self.view.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 30, paddingRight: 0, width: 50, height: 50)
//                        self.searchButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
//                        self.searchButton.adjustsImageWhenHighlighted = false
                        
                        self.loader.stopAnimating()
                        
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        } else {
            self.loader.stopAnimating()
            
            let alert = UIAlertController(title: "Error", message: "Tu conexión a internet está fallando. 🤔 Intenta de nuevo.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    let viewGeneral = UIView()
    let viewContainer = UIView()
    
    let storiesViewContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    let reviewsViewContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    let writeReviewViewContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    func setupUserInfoViewsContainers() {
        
        view.addSubview(viewGeneral)
        viewGeneral.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        viewGeneral.backgroundColor = .black
        
        viewGeneral.addSubview(viewContainer)
        viewContainer.anchor(top: nil, left: viewGeneral.leftAnchor, bottom: nil, right: viewGeneral.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 150)
        viewContainer.backgroundColor = .white
        viewContainer.layer.cornerRadius = 5
        viewContainer.centerYAnchor.constraint(equalTo: viewGeneral.centerYAnchor).isActive = true
        
        viewContainer.addSubview(storiesViewContainer)
        storiesViewContainer.anchor(top: viewContainer.topAnchor, left: viewContainer.leftAnchor, bottom: nil, right: viewContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 150 / 3)
        let storiesTap = UITapGestureRecognizer(target: self, action: #selector(showUserStoriesView))
        storiesViewContainer.addGestureRecognizer(storiesTap)
        
        let storiesIcon = UIImageView()
        storiesIcon.image = #imageLiteral(resourceName: "moments")
        
        let storiesLabel = UILabel()
        storiesLabel.font = UIFont.systemFont(ofSize: 14)
        storiesLabel.lineBreakMode = .byWordWrapping
        storiesLabel.sizeToFit()
        storiesLabel.text = "Momentos"
        
        storiesViewContainer.addSubview(storiesIcon)
        storiesViewContainer.addSubview(storiesLabel)
        storiesIcon.anchor(top: nil, left: storiesViewContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
        storiesIcon.isUserInteractionEnabled = true
        storiesIcon.centerYAnchor.constraint(equalTo: storiesViewContainer.centerYAnchor).isActive = true
        
        storiesLabel.anchor(top: nil, left: storiesIcon.rightAnchor, bottom: nil, right: storiesViewContainer.rightAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        storiesLabel.isUserInteractionEnabled = true
        storiesLabel.centerYAnchor.constraint(equalTo: storiesIcon.centerYAnchor).isActive = true
        
        
        
        viewContainer.addSubview(reviewsViewContainer)
        reviewsViewContainer.anchor(top: storiesViewContainer.bottomAnchor, left: viewContainer.leftAnchor, bottom: nil, right: viewContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 150 / 3)
        reviewsViewContainer.layoutIfNeeded()
        reviewsViewContainer.layer.addBorder(edge: .top, color: .gray, thickness: 1)
        let reviewsTap = UITapGestureRecognizer(target: self, action: #selector(showUserReviewsView))
        reviewsViewContainer.addGestureRecognizer(reviewsTap)
        
        let reviewsIcon = UIImageView()
        reviewsIcon.image = #imageLiteral(resourceName: "reviews")
        
        let reviewsLabel = UILabel()
        reviewsLabel.font = UIFont.systemFont(ofSize: 14)
        reviewsLabel.lineBreakMode = .byWordWrapping
        reviewsLabel.sizeToFit()
        reviewsLabel.text = "Reseñas"
        
        reviewsViewContainer.addSubview(reviewsIcon)
        reviewsViewContainer.addSubview(reviewsLabel)
        reviewsIcon.anchor(top: nil, left: reviewsViewContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
        reviewsIcon.centerYAnchor.constraint(equalTo: reviewsViewContainer.centerYAnchor).isActive = true
        
        reviewsLabel.anchor(top: nil, left: reviewsIcon.rightAnchor, bottom: nil, right: reviewsViewContainer.rightAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        reviewsLabel.centerYAnchor.constraint(equalTo: reviewsIcon.centerYAnchor).isActive = true
        
        
        
        viewContainer.addSubview(writeReviewViewContainer)
        writeReviewViewContainer.anchor(top: reviewsViewContainer.bottomAnchor, left: viewContainer.leftAnchor, bottom: nil, right: viewContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 150 / 3)
        writeReviewViewContainer.layoutIfNeeded()
        writeReviewViewContainer.layer.addBorder(edge: .top, color: .gray, thickness: 1)
        let writeTap = UITapGestureRecognizer(target: self, action: #selector(showWriteReviewView))
        writeReviewViewContainer.addGestureRecognizer(writeTap)
        
        
        let writeIcon = UIImageView()
        writeIcon.image = #imageLiteral(resourceName: "record")
        
        let writeLabel = UILabel()
        writeLabel.font = UIFont.systemFont(ofSize: 14)
        writeLabel.lineBreakMode = .byWordWrapping
        writeLabel.sizeToFit()
        writeLabel.text = "Deja una reseña"
        
        writeReviewViewContainer.addSubview(writeIcon)
        writeReviewViewContainer.addSubview(writeLabel)
        writeIcon.anchor(top: nil, left: writeReviewViewContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
        writeIcon.centerYAnchor.constraint(equalTo: writeReviewViewContainer.centerYAnchor).isActive = true
        
        writeLabel.anchor(top: nil, left: writeIcon.rightAnchor, bottom: nil, right: writeReviewViewContainer.rightAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        writeLabel.centerYAnchor.constraint(equalTo: writeIcon.centerYAnchor).isActive = true
        
        tap = UITapGestureRecognizer(target: self, action: #selector(dismissContainerView))
        viewGeneral.addGestureRecognizer(tap)
        tap.delegate = self
    }
    
    func dismissContainerView() {
        viewGeneral.removeFromSuperview()
        view.removeGestureRecognizer(tap)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view?.isDescendant(of: viewContainer))!{
            return false
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let user = filteredUsers[indexPath.item]
        userSelected = user
        print("user selected: \(user.fullname)")
        
        setupUserInfoViewsContainers()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! UserSearchCell
        
        cell.user = filteredUsers[indexPath.item]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 32) / 3
        return CGSize(width: width, height: width + 20)
    }
    
}
