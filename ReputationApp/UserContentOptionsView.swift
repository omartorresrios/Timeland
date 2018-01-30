//
//  UserContentOptionsView.swift
//  ReputationApp
//
//  Created by Omar Torres on 30/01/18.
//  Copyright © 2018 OmarTorres. All rights reserved.
//

import Foundation
import UIKit

class UserContentOptionsView: UIView {
    
    let storiesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFUIDisplay-Medium", size: 14)
        label.textColor = UIColor.rgb(red: 25, green: 25, blue: 25)
        label.text = "Momentos"
        label.textAlignment = .left
        return label
    }()
    
    let reviewsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFUIDisplay-Medium", size: 14)
        label.textColor = UIColor.rgb(red: 25, green: 25, blue: 25)
        label.text = "Reseñas"
        label.textAlignment = .left
        return label
    }()
    
    let writeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFUIDisplay-Medium", size: 14)
        label.textColor = UIColor.rgb(red: 25, green: 25, blue: 25)
        label.text = "Deja una reseña"
        label.textAlignment = .left
        return label
    }()
    
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
    
    func setupViews() {
        
        addSubview(self.viewGeneral)
        self.viewGeneral.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        self.viewGeneral.backgroundColor = UIColor.rgb(red: 25, green: 25, blue: 25)
        
        viewContainer.transform = CGAffineTransform(translationX: 0, y: self.frame.height)
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
        
        let storiesEmojiView = UIImageView()
        let storiesEmoji = "🍻".image()
        storiesEmojiView.image = storiesEmoji
        
        storiesViewContainer.addSubview(storiesEmojiView)
        storiesViewContainer.addSubview(storiesLabel)
        storiesEmojiView.anchor(top: nil, left: storiesViewContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        storiesEmojiView.isUserInteractionEnabled = true
        storiesEmojiView.centerYAnchor.constraint(equalTo: storiesViewContainer.centerYAnchor).isActive = true
        
        storiesLabel.anchor(top: nil, left: storiesEmojiView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        storiesLabel.isUserInteractionEnabled = true
        storiesLabel.centerYAnchor.constraint(equalTo: storiesEmojiView.centerYAnchor).isActive = true
        
        
        viewContainer.addSubview(reviewsViewContainer)
        reviewsViewContainer.anchor(top: storiesViewContainer.bottomAnchor, left: viewContainer.leftAnchor, bottom: nil, right: viewContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 150 / 3)
        
        let reviewsEmojiView = UIImageView()
        let reviewsEmoji = "👏".image()
        reviewsEmojiView.image = reviewsEmoji
        
        reviewsViewContainer.addSubview(reviewsEmojiView)
        reviewsViewContainer.addSubview(reviewsLabel)
        reviewsEmojiView.anchor(top: nil, left: reviewsViewContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        reviewsEmojiView.centerYAnchor.constraint(equalTo: reviewsViewContainer.centerYAnchor).isActive = true
        
        reviewsLabel.anchor(top: nil, left: reviewsEmojiView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        reviewsLabel.centerYAnchor.constraint(equalTo: reviewsViewContainer.centerYAnchor).isActive = true
        
        
        
        viewContainer.addSubview(writeReviewViewContainer)
        writeReviewViewContainer.anchor(top: reviewsViewContainer.bottomAnchor, left: viewContainer.leftAnchor, bottom: nil, right: viewContainer.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 150 / 3)
        
        let writeEmojiView = UIImageView()
        let writeEmoji = "🗣".image()
        writeEmojiView.image = writeEmoji
        
        writeReviewViewContainer.addSubview(writeEmojiView)
        writeReviewViewContainer.addSubview(writeLabel)
        writeEmojiView.anchor(top: nil, left: writeReviewViewContainer.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        writeEmojiView.centerYAnchor.constraint(equalTo: writeReviewViewContainer.centerYAnchor).isActive = true
        
        writeLabel.anchor(top: nil, left: writeEmojiView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        writeLabel.centerYAnchor.constraint(equalTo: writeEmojiView.centerYAnchor).isActive = true
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
