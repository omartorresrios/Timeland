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
import googleapis

let SAMPLE_RATE = 16000

class UserSearchController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, AudioControllerDelegate {
    
    let httpHelper = HTTPHelper()
    let cellId = "cellId"
    var filteredUsers = [User]()
    var users = [User]()
    var currentUserDic = [String: Any]()
    var collectionView: UICollectionView!
    var userSelected: User!
    var audioData: NSMutableData!
    let customAlertMessage = CustomAlertMessage()
    var tap = UITapGestureRecognizer()
    var alertTap = UITapGestureRecognizer()
    
    let loader: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        indicator.alpha = 1.0
        indicator.startAnimating()
        return indicator
    }()
    
    let processSpeechLoader: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        indicator.alpha = 1.0
        indicator.startAnimating()
        return indicator
    }()
    
    let messageLabel: UILabel = {
        let ml = UILabel()
        ml.font = UIFont(name: "SFUIDisplay-Regular", size: 14)
        ml.numberOfLines = 0
        ml.textAlignment = .center
        return ml
    }()
    
    let userInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    let searchButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "record").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .gray
        button.addTarget(self, action: #selector(recordAudio(_:)), for: .touchUpInside)
        return button
    }()

    let stopButton: UIButton = {
        let button = UIButton()
        button.setTitle("Otra búsqueda", for: .normal)
        button.backgroundColor = .black
        button.addTarget(self, action: #selector(stopAudio(_:)), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    let resetButton: UIButton = {
        let button = UIButton()
        button.setTitle("busca otra", for: .normal)
        button.backgroundColor = .black
        button.addTarget(self, action: #selector(resetAudio), for: .touchUpInside)
        return button
    }()
    
    func wordForSearch(word: String) {
        filteredUsers = self.users.filter { (user) -> Bool in
            return user.fullname.lowercased().contains(word.lowercased())
        }
        
        // Check is there are results
        if filteredUsers.isEmpty {
            messageLabel.isHidden = false
            messageLabel.text = "🙁 No encontramos a esa persona."
            searchButton.tintColor = .gray
            loader.stopAnimating()
        } else {
            messageLabel.isHidden = true
            loader.stopAnimating()
        }

        collectionView?.reloadData()
        
    }
    
    func showCustomAlertMessage() {
        
        collectionView.backgroundColor = UIColor(white: 0, alpha: 0.7)
        
        view.addSubview(customAlertMessage)
        customAlertMessage.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        customAlertMessage.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        customAlertMessage.iconMessage.image = "💩".image()
        customAlertMessage.labelMessage.text = "¡Hubo un problema!\n\n1. Excediste el tiempo de espera (1 min. máx.) ó\n2. Debes hablar un poco más fuerte y claro."
        
        alertTap = UITapGestureRecognizer(target: self, action: #selector(dismissAlertMessage))
        view.addGestureRecognizer(alertTap)
        alertTap.delegate = self
    }
    
    func processSampleData(_ data: Data) -> Void {
        
        audioData.append(data)

        // We recommend sending samples in 100ms chunks
        let chunkSize : Int /* bytes/chunk */ = Int(0.1 /* seconds/chunk */
            * Double(SAMPLE_RATE) /* samples/second */
            * 2 /* bytes/sample */);
        
        if (audioData.length > chunkSize) {
            SpeechRecognitionService.sharedInstance.streamAudioData(audioData, completion: { [weak self] (response, error) in
                
                guard let strongSelf = self else {
                    return
                }

                if let error = error {
                    
                    print("OCURRIÓ UN ERROR: ", error)
                    self?.loader.stopAnimating()
                    
                    self?.showCustomAlertMessage()
                    
                    self?.view.addSubview((self?.resetButton)!)
                    self?.resetButton.anchor(top: nil, left: nil, bottom: self?.view.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 60, paddingRight: 0, width: 50, height: 50)
                    self?.resetButton.centerXAnchor.constraint(equalTo: (self?.view.centerXAnchor)!).isActive = true
                    
                    self?.searchButton.isHidden = true
                    
                } else if let response = response {
                    print("BUSCANDOOOOOO")
                    self?.loader.startAnimating()
                    
                    var finished = false
                    print(response)
                    for result in response.resultsArray! {
                        if let result = result as? StreamingRecognitionResult {
                            if result.isFinal {
                                finished = true
                            }

                            for alternative in result.alternativesArray! {
                                if let transcript = alternative as? SpeechRecognitionAlternative {
                                    for word in transcript.wordsArray! {
                                        if let word = word as? WordInfo {
                                            self?.wordForSearch(word: word.word)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if finished {
                        strongSelf.stopAudio(strongSelf)
                        
                    }
                }
            })
            self.audioData = NSMutableData()
        }
    }
    
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
        
        AudioController.sharedInstance.delegate = self
        
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
        loadAllUsers { (success) in
            if success {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AllUsersLoaded"), object: nil)
            }
        }
        
        
//        searchButton.adjustsImageWhenHighlighted = false
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // General properties of the view
        navigationController?.tabBarController?.tabBar.isHidden = false
        UIApplication.shared.isStatusBarHidden = true
        
    }
    
    func recordAudio(_ sender: NSObject) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
        } catch {
            
        }
        audioData = NSMutableData()
        _ = AudioController.sharedInstance.prepare(specifiedSampleRate: SAMPLE_RATE)
        SpeechRecognitionService.sharedInstance.sampleRate = SAMPLE_RATE
        _ = AudioController.sharedInstance.start()

    }
    
    func stopAudio(_ sender: NSObject) {
        _ = AudioController.sharedInstance.stop()
        SpeechRecognitionService.sharedInstance.stopStreaming()
    }
    
    func resetAudio() {
        _ = AudioController.sharedInstance.stop()
        SpeechRecognitionService.sharedInstance.stopStreaming()
        resetButton.isHidden = true
        searchButton.isHidden = false
    }

    func reachabilityStatusChanged() {
        print("Checking connectivity...")
    }
    
    func showUserStoriesView() {
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
        let writeReviewController = WriteReviewController()

        writeReviewController.userId = userSelected.id
        writeReviewController.userFullname = userSelected.fullname
        writeReviewController.userImageUrl = userSelected.profileImageUrl
        writeReviewController.currentUserDic = currentUserDic

        present(writeReviewController, animated: true) {
            self.viewGeneral.removeFromSuperview()
        }
    }
    
    func loadAllUsers(completion: @escaping (Bool) -> ()) {
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
                        
                        completion(true)
                        
                        self.view.addSubview(self.searchButton)
                        self.searchButton.anchor(top: nil, left: nil, bottom: self.view.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 30, paddingRight: 0, width: 50, height: 50)
                        self.searchButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
                        self.searchButton.adjustsImageWhenHighlighted = false
                        
                        self.view.addSubview(self.stopButton)
                        self.stopButton.anchor(top: nil, left: nil, bottom: self.searchButton.topAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 10, paddingRight: 0, width: 50, height: 50)
                        self.stopButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
                        
                        self.loader.stopAnimating()
                        
                    case .failure(let error):
                        print(error)
                        completion(false)
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
        
        self.view.addSubview(self.viewGeneral)
        self.viewGeneral.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, bottom: self.view.bottomAnchor, right: self.view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        self.viewGeneral.backgroundColor = UIColor.rgb(red: 25, green: 25, blue: 25)
        
        viewContainer.transform = CGAffineTransform(translationX: 0, y: view.frame.height)
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.viewGeneral.addSubview(self.viewContainer)
            self.viewContainer.anchor(top: nil, left: self.viewGeneral.leftAnchor, bottom: nil, right: self.viewGeneral.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 150)
            self.viewContainer.backgroundColor = .white
            self.viewContainer.layer.cornerRadius = 5
            self.viewContainer.centerYAnchor.constraint(equalTo: self.viewGeneral.centerYAnchor).isActive = true
            self.viewContainer.transform = .identity
        }, completion: nil)
        
        viewContainer.addSubview(storiesViewContainer)
        storiesViewContainer.anchor(top: viewContainer.topAnchor, left: viewContainer.leftAnchor, bottom: nil, right: viewContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 150 / 3)
        let storiesTap = UITapGestureRecognizer(target: self, action: #selector(showUserStoriesView))
        storiesViewContainer.addGestureRecognizer(storiesTap)
        
        let storiesEmojiView = UIImageView()
        let storiesEmoji = "🍻".image()
        storiesEmojiView.image = storiesEmoji
        
        storiesViewContainer.addSubview(storiesEmojiView)
        storiesViewContainer.addSubview(storiesLabel)
        storiesEmojiView.anchor(top: nil, left: storiesViewContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        storiesEmojiView.isUserInteractionEnabled = true
        storiesEmojiView.centerYAnchor.constraint(equalTo: storiesViewContainer.centerYAnchor).isActive = true
        
        storiesLabel.anchor(top: nil, left: storiesEmojiView.rightAnchor, bottom: nil, right: storiesViewContainer.rightAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        storiesLabel.isUserInteractionEnabled = true
        storiesLabel.centerYAnchor.constraint(equalTo: storiesEmojiView.centerYAnchor).isActive = true
        
        
        
        viewContainer.addSubview(reviewsViewContainer)
        reviewsViewContainer.anchor(top: storiesViewContainer.bottomAnchor, left: viewContainer.leftAnchor, bottom: nil, right: viewContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 150 / 3)
        reviewsViewContainer.layoutIfNeeded()
        reviewsViewContainer.layer.addBorder(edge: .top, color: .gray, thickness: 1)
        let reviewsTap = UITapGestureRecognizer(target: self, action: #selector(showUserReviewsView))
        reviewsViewContainer.addGestureRecognizer(reviewsTap)
        
        let reviewsEmojiView = UIImageView()
        let reviewsEmoji = "👏".image()
        reviewsEmojiView.image = reviewsEmoji
        
        reviewsViewContainer.addSubview(reviewsEmojiView)
        reviewsViewContainer.addSubview(reviewsLabel)
        reviewsEmojiView.anchor(top: nil, left: reviewsViewContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        reviewsEmojiView.centerYAnchor.constraint(equalTo: reviewsViewContainer.centerYAnchor).isActive = true
        
        reviewsLabel.anchor(top: nil, left: reviewsEmojiView.rightAnchor, bottom: nil, right: reviewsViewContainer.rightAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        reviewsLabel.centerYAnchor.constraint(equalTo: reviewsViewContainer.centerYAnchor).isActive = true
        
        
        
        viewContainer.addSubview(writeReviewViewContainer)
        writeReviewViewContainer.anchor(top: reviewsViewContainer.bottomAnchor, left: viewContainer.leftAnchor, bottom: nil, right: viewContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 150 / 3)
        writeReviewViewContainer.layoutIfNeeded()
        writeReviewViewContainer.layer.addBorder(edge: .top, color: .gray, thickness: 1)
        let writeTap = UITapGestureRecognizer(target: self, action: #selector(showWriteReviewView))
        writeReviewViewContainer.addGestureRecognizer(writeTap)
        
        let writeEmojiView = UIImageView()
        let writeEmoji = "🗣".image()
        writeEmojiView.image = writeEmoji
        
        writeReviewViewContainer.addSubview(writeEmojiView)
        writeReviewViewContainer.addSubview(writeLabel)
        writeEmojiView.anchor(top: nil, left: writeReviewViewContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        writeEmojiView.centerYAnchor.constraint(equalTo: writeReviewViewContainer.centerYAnchor).isActive = true
        
        writeLabel.anchor(top: nil, left: writeEmojiView.rightAnchor, bottom: nil, right: writeReviewViewContainer.rightAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
        writeLabel.centerYAnchor.constraint(equalTo: writeEmojiView.centerYAnchor).isActive = true
        
        tap = UITapGestureRecognizer(target: self, action: #selector(dismissContainerView))
        viewGeneral.addGestureRecognizer(tap)
        tap.delegate = self
    }
    
    let storiesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFUIDisplay-Regular", size: 15)
        label.textColor = UIColor.rgb(red: 25, green: 25, blue: 25)
        label.text = "Momentos"
        label.textAlignment = .left
        return label
    }()
    
    let reviewsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFUIDisplay-Regular", size: 15)
        label.textColor = UIColor.rgb(red: 25, green: 25, blue: 25)
        label.text = "Reseñas"
        label.textAlignment = .left
        return label
    }()
    
    let writeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFUIDisplay-Regular", size: 15)
        label.textColor = UIColor.rgb(red: 25, green: 25, blue: 25)
        label.text = "Deja una reseña"
        label.textAlignment = .left
        return label
    }()
    
    func dismissContainerView() {
        viewGeneral.removeFromSuperview()
        view.removeGestureRecognizer(tap)
    }
    
    func dismissAlertMessage() {
        customAlertMessage.removeFromSuperview()
        collectionView.backgroundColor = .white
        view.removeGestureRecognizer(alertTap)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view?.isDescendant(of: viewContainer))! || (touch.view?.isDescendant(of: customAlertMessage))! {
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


