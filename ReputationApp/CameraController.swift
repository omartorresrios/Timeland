//
//  CameraController.swift
//  ReputationApp
//
//  Created by Omar Torres on 9/10/17.
//  Copyright © 2017 OmarTorres. All rights reserved.
//

import UIKit
import SwiftyCam
import Photos
import AVFoundation
import MediaPlayer
import Alamofire
import Locksmith

class CameraController: SwiftyCamViewController, SwiftyCamViewControllerDelegate, AVCapturePhotoCaptureDelegate {
    
    let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = UIColor.darkGray
        button.setTitle("  Cancel  ", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.layer.cornerRadius = 25
        button.backgroundColor = UIColor.white
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        return button
    }()
    
    let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = UIColor.darkGray
        button.setTitle("  Save  ", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.layer.cornerRadius = 25
        button.backgroundColor = UIColor.white
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        return button
    }()
    
    let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = UIColor.darkGray
        button.setTitle("  Next  ", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.layer.cornerRadius = 25
        button.backgroundColor = UIColor.white
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        return button
    }()
    
    let videoCaption: UITextView = {
        let tv = UITextView()
        tv.layer.cornerRadius = 4
        return tv
    }()
    
    let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .yellow
        button.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        return button
    }()
    
    func handleNext() {
        // TODO: Mejorar la entrada de estos elementos
        
        view.addSubview(videoCaption)
        videoCaption.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 100)
        videoCaption.alpha = 0
        
        view.addSubview(sendButton)
        sendButton.anchor(top: videoCaption.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 4, width: 20, height: 20)
        sendButton.alpha = 0
        
        UIView.animate(withDuration: 0.3, delay: 0.4, options: .curveEaseIn, animations: {
            
            self.videoCaption.alpha = 1
            self.sendButton.alpha = 1
            
        }) { (succes) in
            print("success")
        }
        maximumVideoDuration = 0.0
    }
    
    func handleSend() {
        print("this is the final url: ", videoUrl!)
        // Retreieve Auth_Token from Keychain
        if let userToken = Locksmith.loadDataForUserAccount(userAccount: "AuthToken") {
            
            let authToken = userToken["authenticationToken"] as! String
            print("the current user token: \(userToken)")
            
            DataService.instance.shareVideo(authToken: authToken, videoCaption: self.videoCaption, videoUrl: videoUrl!, duration: finalDuration!)
            
            guard let data = NSData(contentsOf: videoUrl!) else {
                return
            }
            
            print("Final file size: \(Double(data.length / 1048576)) mb")
            
        } else {
            print("Impossible retrieve token")
        }
    }
    
    func handleCancel() {
        self.view.removeFromSuperview()
    }
    
    var circleView = CircleView()
    
    func addCircleView() {
        
        let diceRoll = view.frame.size.width / 2 - (80 / 2)
        let y = view.frame.size.height - 100
        let circleWidth = CGFloat(80)
        let circleHeight = circleWidth
        circleView = CircleView(frame: CGRect(x: diceRoll, y: y, width: circleWidth, height: circleHeight))
        
        view.addSubview(circleView)
        
        circleView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        UIView.animate(withDuration: 0.4) {
            self.circleView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }
        
        circleView.animateCircle(duration: 20.0)
        
    }
    
    let swiftyCamButton: SwiftyCamButton = {
        let button = SwiftyCamButton()
        button.backgroundColor = .white
        button.layer.cornerRadius = 40
        return button
    }()
    
    func swiftyButton() {
        view.addSubview(swiftyCamButton)
        swiftyCamButton.anchor(top: nil, left: nil, bottom: view.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 20, paddingRight: 0, width: 80, height: 80)
        swiftyCamButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraDelegate = self
        defaultCamera = .front
        maximumVideoDuration = 20.0
        shouldUseDeviceOrientation = false
        allowAutoRotate = false
        audioEnabled = true
        
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: "userLoggedIn") == nil {
            //show if not logged in
            DispatchQueue.main.async {
                let loginController = LoginController()
                let navController = UINavigationController(rootViewController: loginController)
                self.present(navController, animated: true, completion: nil)
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        swiftyCamButton.delegate = self
        swiftyButton()
    }
    
    func handleSave() {
        DataService.instance.saveVideo(url: self.videoUrl!, view: self.view)
    }
    
    func setupViews() {
        view.addSubview(cancelButton)
        cancelButton.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 12, paddingLeft: 12, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        view.addSubview(saveButton)
        saveButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 24, paddingBottom: 24, paddingRight: 0, width: 0, height: 50)
        
        view.addSubview(nextButton)
        nextButton.anchor(top: nil, left: nil, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 24, paddingRight: 24, width: 0, height: 50)
    }
    
    //    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
    //        print("taking photo")
    //        print(photo)
    //
    //        let containerView = PreviewPhotoContainerView()
    //        containerView.previewImageView.image = photo
    //
    //        view.addSubview(containerView)
    //        containerView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    //
    //    }
    
    let videoFileOutput = AVCaptureMovieFileOutput()
    let captureSession = AVCaptureSession()
    
    var timerTest: Timer?
    var counter = 20
    var startTime: Double = 0
    var time: Double = 0
    var finalDuration: String?
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("recording video")
        
        startTime = Date().timeIntervalSinceReferenceDate
        timerTest = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        
        swiftyCamButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        UIView.animate(withDuration: 0.4) {
            self.swiftyCamButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.addCircleView()
        }
    }
    
    func update() {
        if counter > 0 {
            print("\(counter) seconds to the end of the world")
            counter -= 1
        }
        time = Date().timeIntervalSinceReferenceDate - startTime
        
        let timeString = String(format: "%.11f", time)
        
        self.finalDuration = timeString
        
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("finishing recording video")
        
        DispatchQueue.main.async {
            // Cancel the timer
            self.timerTest?.invalidate()
            self.timerTest = nil
            self.circleView.pauseAnimation()
            print("video quality was: ", self.videoQuality)
        }
        
    }
    
    var videoUrl: URL?
    var player = AVPlayer()
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        
        self.videoUrl = url
        
        print("this is the url: ", url)
        
        let videoURL = URL(string: url.absoluteString)
        
        player = AVPlayer(url: url)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        view.layer.addSublayer(playerLayer)
        
        player.play()
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil, using: { (_) in
            DispatchQueue.main.async {
                self.player.seek(to: kCMTimeZero)
                self.player.play()
            }
        })
        
        setupViews()
        self.circleView.removeFromSuperview()
        self.swiftyCamButton.removeFromSuperview()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
        
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didChangeZoomLevel zoom: CGFloat) {
        print(zoom)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didSwitchCameras camera: SwiftyCamViewController.CameraSelection) {
        print(camera)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFailToRecordVideo error: Error) {
        print(error)
    }
    
}
