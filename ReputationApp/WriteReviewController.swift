//
//  WriteReviewController.swift
//  ReputationApp
//
//  Created by Omar Torres on 10/12/17.
//  Copyright © 2017 OmarTorres. All rights reserved.
//

import UIKit
import JDStatusBarNotification
import AVFoundation
import AudioBot
import Locksmith
import Alamofire
import CoreGraphics

class WriteReviewController: UIViewController, UITextViewDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    var userReceiverId: String?
    var userReceiverFullname: String?
    var userReceiverImageUrl: String?
    
    var userId: Int?
    var userFullname: String?
    var userImageUrl: String?
    var currentUserDic = [String: Any]()
    
    var actualReview: Review!
    var finalUrl: URL?
    var finalDuration: TimeInterval?
    
    var playing: Bool = false {
        willSet {
            if newValue != playing {
                if newValue {
                    playAudioButton.setImage(#imageLiteral(resourceName: "pause").withRenderingMode(.alwaysTemplate), for: .normal)
                } else {
                    playAudioButton.setImage(#imageLiteral(resourceName: "play").withRenderingMode(.alwaysTemplate), for: .normal)
                }
            }
        }
    }
    
    var startRecordButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .gray
        button.addTarget(self, action: #selector(startRecord), for: .touchUpInside)
        button.setImage(#imageLiteral(resourceName: "record").withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()
    
    let loader: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
        indicator.alpha = 1.0
        indicator.startAnimating()
        return indicator
    }()
    
    let blurView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.8)
        return view
    }()
    
    let sendSuccesView: UIView = {
        let view = UIView()
        view.backgroundColor = .green
        view.layer.cornerRadius = 25
        return view
    }()
    
    let sendSuccesIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = #imageLiteral(resourceName: "clapping_hand")
        return iv
    }()
    
    var progressView: UIProgressView = {
        let progress = UIProgressView()
        return progress
    }()
    
    var playAudioButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .gray
        button.addTarget(self, action: #selector(playAudio), for: .touchUpInside)
        button.setImage(#imageLiteral(resourceName: "play").withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()
    
    let sendView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.backgroundColor = .green
        return view
    }()
    
    let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "send-1").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(sendAudio), for: .touchUpInside)
        return button
    }()
    
    let audioLength: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "0:00"
        label.textColor = UIColor.rgb(red: 25, green: 25, blue: 25)
        label.font = UIFont(name: "SFUIDisplay-Medium", size: 14)
        label.textAlignment = .right
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let tapGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandler(_:)))
        view.addGestureRecognizer(tapGesture)
        
        // Reachability for checking internet connection
//                NotificationCenter.default.addObserver(self, selector: #selector(reachabilityStatusChanged), name: NSNotification.Name(rawValue: "ReachStatusChanged"), object: nil)
        
        addRecordButton()
        
    }
    
    func addRecordButton() {
        view.addSubview(startRecordButton)
        startRecordButton.anchor(top: nil, left: nil, bottom: view.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 20, paddingRight: 0, width: 50, height: 50)
        startRecordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        startRecordButton.adjustsImageWhenHighlighted = false
    }
    
    func playAudio() {
        func tryPlay() {
            do {
                AudioBot.reportPlayingDuration = { duration in
                    
                    let ti = NSInteger(duration)
                    
                    let seconds = String(format: "%02d", ti % 60)
                    let minutes = String(format: "%2d", (ti / 60) % 60)
                    
                    self.audioLength.text = "\(minutes):\(seconds)"
                }
                
                let progressPeriodicReport: AudioBot.PeriodicReport = (reportingFrequency: 10, report: { progress in
                    print("progress: \(progress)")
                    self.actualReview.progress = CGFloat(progress)
                    self.progressView.progress = progress
                })
                let fromTime = TimeInterval(actualReview.progress) * (actualReview.duration)
                try AudioBot.startPlayAudioAtFileURL(actualReview.fileURL, fromTime: fromTime, withProgressPeriodicReport: progressPeriodicReport, finish: { success in
                    self.playing = false
                    self.actualReview.playing = false
                })
                playing = true
                actualReview.playing = true
            } catch {
                print("play error: \(error)")
            }
        }
        if AudioBot.playing {
            AudioBot.pausePlay()
            playing = false
            actualReview.playing = false
        } else {
            tryPlay()
        }
    }
    
    func addSendButton() {
        view.addSubview(sendView)
        sendView.anchor(top: playAudioButton.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 20, width: 40, height: 40)
        sendView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sendAudio)))
        
        sendView.addSubview(sendButton)
        sendButton.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 23, height: 23)
        sendButton.centerYAnchor.constraint(equalTo: sendView.centerYAnchor).isActive = true
        sendButton.centerXAnchor.constraint(equalTo: sendView.centerXAnchor).isActive = true
    }
    
    func addPlayerView(isShowing: Bool) {
        if isShowing == true {
            DispatchQueue.main.async {
                self.view.addSubview(self.playAudioButton)
                self.playAudioButton.anchor(top: nil, left: self.view.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 20, height: 20)
                self.playAudioButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
                self.playAudioButton.adjustsImageWhenHighlighted = false
                
                self.view.addSubview(self.progressView)
                self.progressView.anchor(top: nil, left: self.playAudioButton.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
                self.progressView.centerYAnchor.constraint(equalTo: self.playAudioButton.centerYAnchor).isActive = true
                
                self.view.addSubview(self.audioLength)
                self.audioLength.anchor(top: nil, left: self.progressView.rightAnchor, bottom: nil, right: self.view.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
                self.audioLength.centerYAnchor.constraint(equalTo: self.playAudioButton.centerYAnchor).isActive = true
                
                let duration = NSInteger(self.actualReview.duration)
                let seconds = String(format: "%02d", duration % 60)
                let minutes = (duration / 60) % 60
                
                self.audioLength.text = "\(minutes):\(seconds)"
                
                self.addSendButton()
            }
            
        } else {
            DispatchQueue.main.async {
                self.playAudioButton.removeFromSuperview()
                self.progressView.removeFromSuperview()
                self.audioLength.removeFromSuperview()
            }
        }
    }
    
    func startRecord() {
        DispatchQueue.main.async {
            self.startRecordButton.tintColor = .red
        }
        
        if AudioBot.recording {
            DispatchQueue.main.async {
                self.startRecordButton.tintColor = .gray
            }
            AudioBot.stopRecord { [weak self] fileURL, duration, decibelSamples in
                print("fileURL: \(fileURL)")
                print("duration: \(duration)")
                print("decibelSamples: \(decibelSamples)")
                guard let newFileURL = FileManager.voicememo_audioFileURLWithName(UUID().uuidString, "m4a") else { return }
                guard let _ = try? FileManager.default.copyItem(at: fileURL, to: newFileURL) else { return }
                let voiceMemo = Review(fileURL: newFileURL, duration: duration)
                
                print("newFileURL: ", newFileURL)
                
                self?.actualReview = voiceMemo
                self?.finalUrl = newFileURL
                self?.finalDuration = duration
                self?.addPlayerView(isShowing: true)
            }
            
        } else {
            
            startRecordButton.tintColor = .red
            
            if self.view.subviews.contains(sendView) && self.view.subviews.contains(playAudioButton) && self.view.subviews.contains(progressView) && self.view.subviews.contains(audioLength) {
                print("HAY ELEMENTOS")
                DispatchQueue.main.async {
                    self.playAudioButton.removeFromSuperview()
                    self.progressView.removeFromSuperview()
                    self.audioLength.removeFromSuperview()
                    self.sendView.removeFromSuperview()
                }
            } else {
                print("NO HAY NINGUN ELEMENTO")
            }
            
            do {
                let decibelSamplePeriodicReport: AudioBot.PeriodicReport = (reportingFrequency: 10, report: { decibelSample in
                    print("decibelSample: \(decibelSample)")
                })
                AudioBot.mixWithOthersWhenRecording = true
                try AudioBot.startRecordAudio(forUsage: .normal, withDecibelSamplePeriodicReport: decibelSamplePeriodicReport)
                
            } catch {
                print("record error: \(error)")
            }
        }
    }
    
    func showSuccesMessage() {
        DispatchQueue.main.async {
            
            self.loader.stopAnimating()
            
            self.sendSuccesView.layer.transform = CATransform3DMakeScale(0, 0, 0)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                self.blurView.addSubview(self.sendSuccesView)
                self.sendSuccesView.layer.transform = CATransform3DMakeScale(1, 1, 1)
                
                self.sendSuccesView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
                self.sendSuccesView.centerXAnchor.constraint(equalTo: self.blurView.centerXAnchor).isActive = true
                self.sendSuccesView.centerYAnchor.constraint(equalTo: self.blurView.centerYAnchor).isActive = true
                
                self.sendSuccesView.addSubview(self.sendSuccesIconImageView)
                self.sendSuccesIconImageView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 30, height: 30)
                self.sendSuccesIconImageView.centerXAnchor.constraint(equalTo: self.sendSuccesView.centerXAnchor).isActive = true
                self.sendSuccesIconImageView.centerYAnchor.constraint(equalTo: self.sendSuccesView.centerYAnchor).isActive = true
                
            }, completion: { (completed) in
                
                UIView.animate(withDuration: 0.5, delay: 0.75, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                    
                    self.sendSuccesView.layer.transform = CATransform3DMakeScale(0.1, 0.1, 0.1)
                    self.sendSuccesView.alpha = 0
                    
                }, completion: { (_) in
                    
                    DispatchQueue.main.async {
                        self.blurView.removeFromSuperview()
                        self.addPlayerView(isShowing: false)
                        self.sendView.removeFromSuperview()
                        self.dismiss(animated: true, completion: nil)
                    }
                })
            })
        }
    }
    
    func sendAudio() {
        
        DispatchQueue.main.async {
            
            self.view.addSubview(self.blurView)
            self.blurView.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, bottom: self.view.bottomAnchor, right: self.view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            
            self.blurView.addSubview(self.loader)
            self.loader.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            self.loader.centerYAnchor.constraint(equalTo: self.blurView.centerYAnchor).isActive = true
            self.loader.centerXAnchor.constraint(equalTo: self.blurView.centerXAnchor).isActive = true
            
        }
        
        if let userToken = Locksmith.loadDataForUserAccount(userAccount: "AuthToken") {
            
            let authToken = userToken["authenticationToken"] as! String
            print("the current user token: \(userToken)")
            
            DataService.instance.shareAudio(authToken: authToken, userId: userId!, audioUrl: self.finalUrl!, duration: self.finalDuration!, completion: { (success) in
                if success {
                    self.showSuccesMessage()
                }
            })
        }
    }
    
    // define a variable to store initial touch position
    var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
    
    func panGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: self.view?.window)
        
        if sender.state == UIGestureRecognizerState.began {
            initialTouchPoint = touchPoint
        } else if sender.state == UIGestureRecognizerState.changed {
            if touchPoint.y - initialTouchPoint.y > 0 {
                self.view.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y, width: self.view.frame.size.width, height: self.view.frame.size.height)
            }
        } else if sender.state == UIGestureRecognizerState.ended || sender.state == UIGestureRecognizerState.cancelled {
            if touchPoint.y - initialTouchPoint.y > 100 {
                self.dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                })
            }
        }
    }
}
