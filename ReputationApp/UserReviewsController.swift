//
//  UserReviewsController.swift
//  ReputationApp
//
//  Created by Omar Torres on 10/12/17.
//  Copyright © 2017 OmarTorres. All rights reserved.
//

import UIKit
import Locksmith
import Alamofire
import AudioBot
import MediaPlayer

private let cellId = "cellId"

class UserReviewsController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
    var userId: Int?
    var userFullname: String?
    var userImageUrl: String?
    var currentUserDic = [String: Any]()
    var reviews = [[String: Any]]()
    var reviewAudios = [Review]()
    var tap = UITapGestureRecognizer()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .black
        return label
    }()
    
    let closeView: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "close").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .gray
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = .white
        
        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .vertical
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
            layout.sectionInset = UIEdgeInsets(top: 31, left: 0, bottom: 0, right: 0)
        }
        
        collectionView?.register(UserReviewsCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.isPagingEnabled = false
        
//        let tapGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandler(_:)))
//        view.addGestureRecognizer(tapGesture)
        
        AudioBot.prepareForNormalRecord()
        
        tap = UITapGestureRecognizer(target: self, action: #selector(dismissContainerView))
        view.addGestureRecognizer(tap)
        tap.delegate = self
        
        loadUserReviews()
        
        view.addSubview(closeView)
        closeView.anchor(top: view.topAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 15, height: 15)
        closeView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeViewController)))
        
    }
    
    func closeViewController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func dismissContainerView() {
        containerView.removeFromSuperview()
        containerView.playing = false
        AudioBot.pausePlay()
        containerView.audioLengthLabel.text = "0:00"
        containerView.progressView.progress = 0
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view?.isDescendant(of: containerView))!{
            return false
        }
        return true
    }
    
    //    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    //        let cell = UserReviewsCell()
    //        cell.letsGo = false
    //    }
    
    //    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    ////        let index = targetContentOffset.pointee.x / view.frame.width
    ////        print("index: ", index)
    ////        let indexPath = IndexPath(item: Int(index), section: 0)
    ////
    ////        let reviewAudio = reviewAudios[indexPath.item]
    //        let cell = UserReviewsCell()
    //        cell.letsGo = false
    ////        cell.playAudio(url: reviewAudio.fileURL, isPlay: false)
    //
    //    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        //        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! UserReviewsCell
        
        //        if let cell = cell as? UserReviewsCell {
        //            if let play = cell.player {
        //                print("stopped")
        //                play.pause()
        ////                cell.player = nil
        ////                cell.audioSlider.value = 0
        ////                cell.isPlaying = false
        //                print("player deallocated")
        //            } else {
        //                print("player was already deallocated")
        //            }
        //        }
        //
        
        
        
        
        
        //        var reviewAudio = reviewAudios[indexPath.item]
        //        cell.letsGo = false
        //        cell.playAudio(url: reviewAudio.fileURL)
        
        
    }
    
    func parseDuration(_ timeString:String) -> TimeInterval {
        guard !timeString.isEmpty else {
            return 0
        }
        
        var interval:Double = 0
        
        let parts = timeString.components(separatedBy: ":")
        for (index, part) in parts.reversed().enumerated() {
            interval += (Double(part) ?? 0) * pow(Double(60), Double(index))
        }
        
        return interval
    }
    
    func loadUserReviews() {
        // Retreieve Auth_Token from Keychain
        if let userToken = Locksmith.loadDataForUserAccount(userAccount: "AuthToken") {
            
            let authToken = userToken["authenticationToken"] as! String
            
            print("Token: \(userToken)")
            
            // Set Authorization header
            let header = ["Authorization": "Token token=\(authToken)"]
            
            print("THE HEADER: \(header)")
            
            Alamofire.request("https://protected-anchorage-18127.herokuapp.com/api/\(userFullname!)/reviews", method: .get, parameters: nil, encoding: URLEncoding.default, headers: header).responseJSON { (response) in
                switch response.result {
                case .success(let JSON):
                    
                    print("THE USER REVIEWS: \(JSON)")
                    
                    let jsonArray = JSON as! NSDictionary
                    let reviewsArray = jsonArray["reviews"] as! NSArray
                    
                    if reviewsArray.count == 0 {
                        self.view.addSubview(self.messageLabel)
                        self.messageLabel.anchor(top: nil, left: self.view.leftAnchor, bottom: nil, right: self.view.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
                        self.messageLabel.text = "No tiene reviews :("
                    }
                    
                    reviewsArray.forEach({ (value) in
                        guard let reviewDictionary = value as? [String: Any] else { return }
                        print("reviewDictionary: \(reviewDictionary)")
                        
                        let duration = self.parseDuration(reviewDictionary["duration"] as! String)
                        let url = reviewDictionary["audio"] as! String
                        
                        let reviewAudio = Review(fileURL: URL(string: reviewDictionary["audio"] as! String)!, duration: duration)
                        self.reviewAudios.append(reviewAudio)
                        
                        //                        let reviewDict = Review1(reviewDictionary: reviewDictionary)
                        self.reviews.append(reviewDictionary)
                        
                        
                        //                        let review = Review1(fileURL: URL(string: url)!, duration: duration)
                        //                        self.reviews.append(review)
                        self.collectionView?.reloadData()
                    })
                    
                case .failure(let error):
                    print(error)
                }
            }
            
        }
    }
    
//    // define a variable to store initial touch position
//    var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
//    
//    func panGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
//        let touchPoint = sender.location(in: self.view?.window)
//        
//        if sender.state == UIGestureRecognizerState.began {
//            initialTouchPoint = touchPoint
//        } else if sender.state == UIGestureRecognizerState.changed {
//            if touchPoint.y - initialTouchPoint.y > 0 {
//                self.view.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y, width: self.view.frame.size.width, height: self.view.frame.size.height)
//            }
//        } else if sender.state == UIGestureRecognizerState.ended || sender.state == UIGestureRecognizerState.cancelled {
//            if touchPoint.y - initialTouchPoint.y > 100 {
//                self.dismiss(animated: true, completion: nil)
//            } else {
//                UIView.animate(withDuration: 0.3, animations: {
//                    self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
//                })
//            }
//        }
//    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return reviews.count
    }
    
    let containerView = PreviewAudioContainerView()
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! UserReviewsCell
        
        cell.backgroundColor = .white
        
        var review = reviews[indexPath.item]
        var audioReview = reviewAudios[indexPath.item]

        var receiverData = review["receiver"] as! [String: Any]

        var senderData = review["sender"] as! [String: Any]

        let fullName = senderData["fullname"] as! String
        cell.fullnameLabel.text = fullName

        let avatarUrl = senderData["avatarUrl"] as! String
        cell.profileImageView.loadImage(urlString: avatarUrl)
        
        let createdAt  = review["createdAt"] as! String
        
        // deleting the Z in the final
        let zEndIndex = createdAt.index(createdAt.endIndex, offsetBy: -1)
        let finalWihtOutZ = createdAt.substring(to: zEndIndex)
        
        // deleting the last 3 characters
        let last4endIndex = finalWihtOutZ.index(finalWihtOutZ.endIndex, offsetBy: -4)
        let finalWihtOut4 = finalWihtOutZ.substring(to: last4endIndex)
        
        // adding the Z to the end
        let finalCreatedAt = finalWihtOut4 + "Z"
        
        let dateFormatter = DateFormatter()
        let tempLocale = dateFormatter.locale // save locale temporarily
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let date = dateFormatter.date(from: finalCreatedAt)!
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        dateFormatter.locale = tempLocale // reset the locale
        let dateString = dateFormatter.string(from: date)
        print("EXACT_DATE : \(dateString)")
        
        cell.timeLabel.text = date.timeAgoDisplay()

        cell.goToListen = {

            self.containerView.fullnameLabel.text = fullName

            let duration = NSInteger(audioReview.duration)
            let seconds = String(format: "%02d", duration % 60)
            let minutes = (duration / 60) % 60

            self.containerView.audioLengthLabel.text = "\(minutes):\(seconds)"

            self.view.addSubview(self.containerView)
            self.containerView.anchor(top: nil, left: self.view.leftAnchor, bottom: nil, right: self.view.rightAnchor, paddingTop: 0, paddingLeft: 4, paddingBottom: 0, paddingRight: 4, width: 0, height: 60)

            self.containerView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true

            self.containerView.playOrPauseAudioAction = { [weak self] cell, progressView in
                func tryPlay() {
                    do {
                        AudioBot.reportPlayingDuration = { duration in

                            let ti = NSInteger(duration)

                            let seconds = String(format: "%02d", ti % 60)
                            let minutes = String(format: "%2d", (ti / 60) % 60)

                            self?.containerView.audioLengthLabel.text = "\(minutes):\(seconds)"
                        }
                        let progressPeriodicReport: AudioBot.PeriodicReport = (reportingFrequency: 10, report: { progress in
                            print("progress: \(progress)")
                            audioReview.progress = CGFloat(progress)
                            progressView.progress = progress
                        })

                        let fromTime = TimeInterval(audioReview.progress) * audioReview.duration
                        try AudioBot.startPlayAudioAtFileURL(audioReview.fileURL, fromTime: fromTime, withProgressPeriodicReport: progressPeriodicReport, finish: { success in
                            audioReview.playing = false
                            cell.playing = false
                        })
                        print("LET SEE: ", audioReview.fileURL)
                        audioReview.playing = true
                        cell.playing = true
                    } catch {
                        print("play error: \(error)")
                    }
                }
                if AudioBot.playing {
                    AudioBot.pausePlay()
                    audioReview.playing = false
                    cell.playing = false

                    //                tryPlay()
                    //                review.playing = false
                    //                cell.playing = false
                    //                if let strongSelf = self {
                    //                    for index in 0..<(strongSelf.reviews).count {
                    //                        var voiceMemo = strongSelf.reviews[index]
                    //                        if AudioBot.playingFileURL == voiceMemo.fileURL {
                    //                            let indexPath = IndexPath(row: index, section: 0)
                    //                            if let cell = collectionView.cellForItem(at: indexPath) as? UserReviewsCell {
                    //                                voiceMemo.playing = false
                    //                                cell.playing = false
                    //                            }
                    //                            break
                    //                        }
                    //                    }
                    //                }
                    //                    if AudioBot.playingFileURL != review.fileURL {
                    //                        tryPlay()
                    //                    }
                } else {
                    tryPlay()
                }
            }
        }
        return cell
    }
    
    
//        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//            return 0
//        }
    
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
            return 1
        }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.width
        var height: CGFloat = 50 + 8 + 8 //username userprofileimageview
        height += 30
        height += 10
        return CGSize(width: (width - 2) / 3, height: height)
    }
    
}
