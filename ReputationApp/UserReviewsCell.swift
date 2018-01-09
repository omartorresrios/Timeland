//
//  UserReviewsCell.swift
//  ReputationApp
//
//  Created by Omar Torres on 31/12/17.
//  Copyright © 2017 OmarTorres. All rights reserved.
//

import UIKit
import AudioBot
import MediaPlayer

class UserReviewsCell: UICollectionViewCell {
    
    let fullnameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont(name: "SFUIDisplay-Medium", size: 14)
        label.textAlignment = .left
        return label
    }()
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        return iv
    }()
    
    lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "play")
        button.setImage(image, for: UIControlState())
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .black
        //        button.addTarget(self, action: #selector(handlePause), for: .touchUpInside)
        
        return button
    }()
    
    var playing: Bool = false {
        willSet {
            if newValue != playing {
                if newValue {
                    playButton.setImage(UIImage(named: "pause"), for: UIControlState())
                } else {
                    playButton.setImage(UIImage(named: "play"), for: UIControlState())
                }
            }
        }
    }
    
    let progressView: UIProgressView = {
        let progress = UIProgressView()
        return progress
    }()
    
    lazy var audioSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumTrackTintColor = .red
        slider.maximumTrackTintColor = .gray
        slider.setThumbImage(UIImage(named: "thumb"), for: UIControlState())
        
        //        slider.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
        
        return slider
    }()
    
    let audioLengthLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "00:00"
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textAlignment = .right
        return label
    }()
    
    let currentTimeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "00:00"
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 13)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 40, height: 40)
        profileImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        addSubview(fullnameLabel)
        fullnameLabel.anchor(top: profileImageView.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        fullnameLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(previewAudio))
        self.addGestureRecognizer(tap)
        
        
        //        addSubview(currentTimeLabel)
        //        currentTimeLabel.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 50, height: 24)
        //        currentTimeLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        //
        //        addSubview(progressView)
        //        progressView.anchor(top: nil, left: currentTimeLabel.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        //        progressView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        //
        //        addSubview(audioLengthLabel)
        //        audioLengthLabel.anchor(top: nil, left: progressView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 10, paddingBottom: 0, paddingRight: 10, width: 50, height: 24)
        //        audioLengthLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        //
        //        addSubview(playButton)
        //        playButton.anchor(top: currentTimeLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 10, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
    //    func configureWithVoiceMemo(_ userReview: Review1) {
    //
    //        playing = userReview.playing
    //
    //        audioLengthLabel.text = String(format: "%.1f", userReview.duration)
    //
    //        progressView.progress = Float(userReview.progress)
    //    }
    
    var goToListen : (() -> Void)?
    
    
    
    
    func previewAudio() {
        goToListen!()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
