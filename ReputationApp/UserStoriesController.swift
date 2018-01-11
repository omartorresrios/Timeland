//
//  UserStoriesController.swift
//  ReputationApp
//
//  Created by Omar Torres on 10/12/17.
//  Copyright © 2017 OmarTorres. All rights reserved.
//

import UIKit
import Locksmith
import Alamofire
import Haneke
import MediaPlayer

class UserStoriesController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var userId: Int?
    var userFullname: String?
    var userImageUrl: String?
    var currentUserDic = [String: Any]()
    var images: [NSURL] = []
    var urls = [String]()
    var durations = [String]()
    let userFeedCell = "userFeedCell"
    var eventVideos = [Event]()
    var stories = [[String: Any]]()
    
    let closeView: UIButton = {
        let button = UIButton(type: .system)
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
            layout.sectionInset = UIEdgeInsets(top: 31, left: 8, bottom:8, right: 8)
        }
        
        // Register cell classes
        collectionView?.register(UserFeedCell.self, forCellWithReuseIdentifier: userFeedCell)
        collectionView?.isPagingEnabled = false
        
        
        
        loadUserEvents()
        
        view.addSubview(closeView)
        closeView.anchor(top: view.topAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 15, height: 15)
        closeView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeViewController)))
    }
    
    func closeViewController() {
        self.dismiss(animated: true, completion: nil)
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
    
    var finalDuration: TimeInterval?
    
    func loadUserEvents() {
        // Retreieve Auth_Token from Keychain
        if let userToken = Locksmith.loadDataForUserAccount(userAccount: "AuthToken") {
            
            let authToken = userToken["authenticationToken"] as! String
            
            print("Token: \(userToken)")
            
            // Set Authorization header
            let header = ["Authorization": "Token token=\(authToken)"]
            
            print("THE HEADER: \(header)")
            
            Alamofire.request("https://protected-anchorage-18127.herokuapp.com/api/\(userFullname!)/events", method: .get, parameters: nil, encoding: URLEncoding.default, headers: header).responseJSON { response in
                
                print("request: \(response.request!)") // original URL request
                print("response: \(response.response!)") // URL response
                print("response data: \(response.data!)") // server data
                print("result: \(response.result)") // result of response serialization
                
                if let JSON = response.result.value as? [[String: Any]] {
                    print("\nTHE USER EVENTS: \(JSON)\n")
                    
                    for item in JSON {
                        guard let storieDictionary = item as? [String: Any] else { return }
                        print("storieDictionary: \(storieDictionary)")
                        
                        self.stories.append(storieDictionary)
                        
                        let event_url = item["event_url"] as! String
                        
                        let duration = item["duration"] as! String
                        self.finalDuration = self.parseDuration(duration)
                        
                        
                        print("\nevent_url: ", event_url)
                        
                        let endIndex = event_url.index(event_url.endIndex, offsetBy: -11)
                        let finalEventUrl = event_url.substring(to: endIndex)
                        
                        let cache = Shared.dataCache
                        let URL = NSURL(string: finalEventUrl)!
                        
                        let eventVideo = Event(duration: self.finalDuration!)
                        self.eventVideos.append(eventVideo)
                        print("event's video: ", eventVideo.duration)
                        
                        cache.fetch(URL: URL as URL).onSuccess { (data) in
                            
                            let path = NSURL(string: DiskCache.basePath())!.appendingPathComponent("shared-data/original")
                            let cached = DiskCache(path: (path?.absoluteString)!).path(forKey: String(describing: URL))
                            let file = NSURL(fileURLWithPath: cached)
                            
                            self.images.append(file)
                            self.urls.append(finalEventUrl)
                            
                            self.collectionView?.reloadData()
                            
                        }
                    }
                }
            }
        }
    }
    
    // define a variable to store initial touch position
    var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)

    func panGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: self.previewVideoContainerView.view?.window)

        if sender.state == UIGestureRecognizerState.began {
            initialTouchPoint = touchPoint
        } else if sender.state == UIGestureRecognizerState.changed {
            if touchPoint.y - initialTouchPoint.y > 0 {
                self.previewVideoContainerView.view.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y, width: self.previewVideoContainerView.view.frame.size.width, height: self.previewVideoContainerView.view.frame.size.height)
            }
        } else if sender.state == UIGestureRecognizerState.ended || sender.state == UIGestureRecognizerState.cancelled {
            if touchPoint.y - initialTouchPoint.y > 100 {
                self.previewVideoContainerView.dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    self.previewVideoContainerView.view.frame = CGRect(x: 0, y: 0, width: self.previewVideoContainerView.view.frame.size.width, height: self.previewVideoContainerView.view.frame.size.height)
                })
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    let previewVideoContainerView = PreviewVideoContainerView()
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: userFeedCell, for: indexPath) as! UserFeedCell
        
        let image = self.images[indexPath.item].absoluteString!
        let url = self.urls[indexPath.item]
        let event = eventVideos[indexPath.item]
        let storie = stories[indexPath.item]
        
        let createdAt = storie["created_at"] as! String
        let fullname = storie["user_fullname"] as! String
        
        if let url = URL(string: image) {
            let asset:AVAsset = AVAsset(url: url)
            
            // Fetch the duration of the video
            let durationSeconds = CMTimeGetSeconds(asset.duration)
            let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
            
            assetImgGenerate.appliesPreferredTrackTransform = true
            
            // Jump to the third (1/3) of the video and fetch the thumbnail from there (600 is the timescale and is a multiplier of 24fps, 25fps, 30fps..)
            let time        : CMTime = CMTimeMakeWithSeconds(durationSeconds/3.0, 600)
            var img         : CGImage
            do {
                img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                let frameImg: UIImage = UIImage(cgImage: img)
                
                cell.photoImageView.image =  frameImg

                let duration = NSInteger(event.duration)
                let seconds = String(format: "%02d", duration % 60)
                let minutes = (duration / 60) % 60
                cell.videoLengthLabel.setTitle("\(minutes):\(seconds)", for: .normal)
                
                
                
            } catch let error as NSError {
                print("ERROR: \(error)")
                cell.photoImageView.image = nil
            }
        } else {
            print("THE URL DOES NOT EXIST")
        }
        
        cell.goToWatch = {
            
            
            self.present(self.previewVideoContainerView, animated: false, completion: nil)
            
            let videoURL = URL(string: url)
            let player = AVPlayer(url: videoURL!)
            let playerLayer = AVPlayerLayer(player: player)
            
            playerLayer.frame = self.previewVideoContainerView.view.bounds
            
            self.previewVideoContainerView.view.layer.addSublayer(playerLayer)
            
            playerLayer.zPosition = -5
            
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
            
            
            
            let timeLabel = UILabel()
            timeLabel.tintColor = .black
            timeLabel.backgroundColor = .yellow
            timeLabel.text = date.timeAgoDisplay()
            
            self.previewVideoContainerView.videoLengthLabel.setTitle(timeLabel.text, for: .normal)
            self.previewVideoContainerView.userNameLabel.text = fullname
            
            let tapGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panGestureRecognizerHandler(_:)))
            self.previewVideoContainerView.view.addGestureRecognizer(tapGesture)
            
            
            
            player.play()
        }
        
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
        return CGSize(width: width, height: width + 60)
    }
    
    
}
