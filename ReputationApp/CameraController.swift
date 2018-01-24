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
import GoogleSignIn

class CameraController: SwiftyCamViewController, SwiftyCamViewControllerDelegate, AVCapturePhotoCaptureDelegate {
    
    let videoCaption: UITextView = {
        let tv = UITextView()
        tv.layer.cornerRadius = 4
        return tv
    }()
    
    let sendLabel = UILabel()
    
    var circleView = CircleView()
    let videoFileOutput = AVCaptureMovieFileOutput()
    let captureSession = AVCaptureSession()
    
    var timerTest: Timer?
    var counter = 20
    var startTime: Double = 0
    var time: Double = 0
    var finalDuration: String?
    var videoUrl: URL?
    var player = AVPlayer()
    
    func handleSend() {
        
        print("this is the final url: ", videoUrl!)
        // Retreieve Auth_Token from Keychain
        if let userToken = Locksmith.loadDataForUserAccount(userAccount: "AuthToken") {
            
            let authToken = userToken["authenticationToken"] as! String
            print("the current user token: \(userToken)")
            
            DataService.instance.shareVideo(authToken: authToken, videoCaption: self.videoCaption, videoUrl: videoUrl!, duration: finalDuration!, completion: { (success) in
                if success {
                    self.blurView.removeFromSuperview()
                    self.sendButtomImageView.removeFromSuperview()
                    let appDel: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDel.logUser(forAppDelegate: false)

                }
            })
            
            guard let data = NSData(contentsOf: videoUrl!) else {
                return
            }
            
            print("Final file size: \(Double(data.length / 1048576)) mb")
            
            
        } else {
            print("Impossible retrieve token")
        }
    }
    
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
    
    let fakeView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    let fakeButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .gray
        button.isUserInteractionEnabled = false
        button.layer.cornerRadius = 40
        return button
    }()
    
    let swiftyCamButton: SwiftyCamButton = {
        let button = SwiftyCamButton()
        button.backgroundColor = .white
        button.layer.cornerRadius = 40
        button.isUserInteractionEnabled = false
        return button
    }()
    
    func swiftyButton() {
        
        view.addSubview(swiftyCamButton)
        swiftyCamButton.anchor(top: nil, left: nil, bottom: view.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 20, paddingRight: 0, width: 80, height: 80)
        swiftyCamButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        let button = UIButton()
        button.setTitle("jaja", for: .normal)
        button.backgroundColor = .yellow
        button.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
        view.addSubview(button)
        button.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 20, height: 40)
        button.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraDelegate = self
        defaultCamera = .front
        maximumVideoDuration = 20.0
        shouldUseDeviceOrientation = false
        allowAutoRotate = false
        audioEnabled = true
        
        fakeViews()
    }
    
    func fakeViews() {
        view.addSubview(fakeView)
        fakeView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        view.addSubview(fakeButton)
        fakeButton.anchor(top: nil, left: nil, bottom: view.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 20, paddingRight: 0, width: 80, height: 80)
        fakeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(SetupSwiftyCamButton), name: NSNotification.Name(rawValue: "AllUsersLoaded"), object: nil)
    }
    
    func SetupSwiftyCamButton() {
        swiftyCamButton.delegate = self
        fakeView.removeFromSuperview()
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
            self.fakeButton.removeFromSuperview()
        }, completion: nil)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            self.swiftyButton()
        }, completion: nil)
        
        swiftyCamButton.isUserInteractionEnabled = true
    }
    
    func handleLogout() {
        clearLoggedinFlagInUserDefaults()
        clearAPITokensFromKeyChain()
        GIDSignIn.sharedInstance().signOut()
        
        DispatchQueue.main.async {
            let loginController = LoginController()
            let navController = UINavigationController(rootViewController: loginController)
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    // 1. Clears the NSUserDefaults flag
    func clearLoggedinFlagInUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "userLoggedIn")
        defaults.synchronize()
    }
    
    
    // 3. Clears API Auth token from Keychain
    func clearAPITokensFromKeyChain() {
        // clear API Auth Token
        try! Locksmith.deleteDataForUserAccount(userAccount: "AuthToken")
        try! Locksmith.deleteDataForUserAccount(userAccount: "currentUserId")
        try! Locksmith.deleteDataForUserAccount(userAccount: "currentUserName")
        try! Locksmith.deleteDataForUserAccount(userAccount: "currentUserAvatar")
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("recording video")
        
        startTime = Date().timeIntervalSinceReferenceDate
        timerTest = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        
        DispatchQueue.main.async {
            self.swiftyCamButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            UIView.animate(withDuration: 0.4) {
                self.swiftyCamButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                self.addCircleView()
            }
        }
    }
    
    func update() {
        DispatchQueue.main.async {
            if self.counter > 0 {
                print("\(self.counter) seconds to the end of the world")
                self.counter -= 1
            }
            self.time = Date().timeIntervalSinceReferenceDate - self.startTime
            
            let timeString = String(format: "%.11f", self.time)
            
            self.finalDuration = timeString
        }
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
    
    let blurView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.8)
        view.isUserInteractionEnabled = true
        return view
    }()
    
    let sendView: UIView = {
        let view = UIView()
        view.backgroundColor = .green
        view.layer.cornerRadius = 25
        return view
    }()
    
    let sendButtomImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = #imageLiteral(resourceName: "hand")
        return iv
    }()
    
    func setupBlurView() {
        view.addSubview(blurView)
        blurView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    }
    
    func setupSendButton() {
        
        blurView.addSubview(sendView)
        sendView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        sendView.centerXAnchor.constraint(equalTo: blurView.centerXAnchor).isActive = true
        sendView.centerYAnchor.constraint(equalTo: blurView.centerYAnchor).isActive = true
        
        sendView.addSubview(sendButtomImageView)
        sendButtomImageView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 30, height: 30)
        sendButtomImageView.centerXAnchor.constraint(equalTo: sendView.centerXAnchor).isActive = true
        sendButtomImageView.centerYAnchor.constraint(equalTo: sendView.centerYAnchor).isActive = true
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        
        videoUrl = url
        
        print("this is the url: ", url)
        
        DispatchQueue.main.async {
            self.circleView.removeFromSuperview()
            self.swiftyCamButton.removeFromSuperview()
            
            self.setupBlurView()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.setupSendButton()
        }
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
