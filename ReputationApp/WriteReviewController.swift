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
    
    var startRecordButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .gray
        button.addTarget(self, action: #selector(startRecord), for: .touchUpInside)
        button.setImage(#imageLiteral(resourceName: "record").withRenderingMode(.alwaysTemplate), for: .normal)
        return button
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
    
    var sendAudioButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "send").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .yellow
        return button
    }()
    
    let audioLength: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "0:00"
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textAlignment = .right
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("userId: ", userId)
        print("userFullname: ", userFullname)
        print("userImageUrl: ", userImageUrl)
        print("currentUserDic: ", currentUserDic)
        view.backgroundColor = .white
        
        let tapGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandler(_:)))
        view.addGestureRecognizer(tapGesture)
        
        // Initialize functions
        //        subviewsAnchors()
        
        // Reachability for checking internet connection
        //        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityStatusChanged), name: NSNotification.Name(rawValue: "ReachStatusChanged"), object: nil)
        //        view.addSubview(stopButton)
        //        stopButton.anchor(top: nil, left: nil, bottom: view.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 20, paddingRight: 0, width: 30, height: 30)
        //        stopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(startRecordButton)
        startRecordButton.anchor(top: nil, left: nil, bottom: view.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 20, paddingRight: 0, width: 50, height: 50)
        startRecordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        startRecordButton.adjustsImageWhenHighlighted = false
        
    }
    
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
        view.addSubview(sendAudioButton)
        sendAudioButton.anchor(top: playAudioButton.bottomAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 15, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 40, height: 40)
        sendAudioButton.addTarget(self, action: #selector(send), for: .touchUpInside)
    }
    
    func addPlayerView(isShowing: Bool) {
        if isShowing == true {
            view.addSubview(playAudioButton)
            playAudioButton.anchor(top: nil, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 20, height: 20)
            playAudioButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            playAudioButton.adjustsImageWhenHighlighted = false
            
            view.addSubview(progressView)
            progressView.anchor(top: nil, left: playAudioButton.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            progressView.centerYAnchor.constraint(equalTo: playAudioButton.centerYAnchor).isActive = true
            
            view.addSubview(audioLength)
            audioLength.anchor(top: nil, left: progressView.rightAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
            audioLength.centerYAnchor.constraint(equalTo: playAudioButton.centerYAnchor).isActive = true
            
            let duration = NSInteger(actualReview.duration)
            let seconds = String(format: "%02d", duration % 60)
            let minutes = (duration / 60) % 60
            
            self.audioLength.text = "\(minutes):\(seconds)"
            
            addSendButton()
        } else {
            playAudioButton.removeFromSuperview()
            progressView.removeFromSuperview()
            audioLength.removeFromSuperview()
        }
        
    }
    
    var actualReview: Review!
    var finalUrl: URL?
    var finalDuration: TimeInterval?
    
    func startRecord() {
        startRecordButton.tintColor = .red
        if AudioBot.recording {
            startRecordButton.tintColor = .gray
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
            sendAudioButton.removeFromSuperview()
            addPlayerView(isShowing: false)
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
    
    func send() {
        
        if let userToken = Locksmith.loadDataForUserAccount(userAccount: "AuthToken") {
            
            let authToken = userToken["authenticationToken"] as! String
            print("the current user token: \(userToken)")
            
            let parameters = ["duration": finalDuration!] as [String : Any]
            
            let header = ["Authorization": "Token token=\(authToken)"]
            
            let url = URL(string: "https://protected-anchorage-18127.herokuapp.com/api/\(userId!)/speak")!
            
            Alamofire.upload(multipartFormData: { multipartFormData in
                
                multipartFormData.append(self.finalUrl!, withName: "audio", fileName: ".m4a", mimeType: "audio/m4a")
                
                for (key, value) in parameters {
                    multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key)
                }
                
            }, usingThreshold: UInt64.init() , to: url, method: .post, headers: header, encodingCompletion: { encodingResult in
                
                switch encodingResult {
                case .success(let upload, _, _):
                    
                    upload.responseJSON { response in
                        print("request: \(response.request!)") // original URL request
                        print("response: \(response.response!)") // URL response
                        print("response data: \(response.data!)") // server data
                        print("result: \(response.result)") // result of response serialization
                        
                        if let JSON = response.result.value {
                            print("JSON: \(JSON)")
                        }
                    }
                    
                case .failure(let encodingError):
                    print("Alamofire proccess failed", encodingError)
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
