//
//  PreviewVideoContainerView.swift
//  ReputationApp
//
//  Created by Omar Torres on 9/10/17.
//  Copyright © 2017 OmarTorres. All rights reserved.
//

import UIKit
import Photos
import Locksmith
import Alamofire

class PreviewVideoContainerView: UIViewController {
    
    let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        return label
    }()
    
    var url: URL?
    
    let videoLengthLabel: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        button.backgroundColor = .black
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.setTitle("0:00", for: .normal)
        button.tintColor = .white
        return button
    }()
    
    func handleCancel() {
        view.removeFromSuperview()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(userNameLabel)
        userNameLabel.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 8, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        view.addSubview(videoLengthLabel)
        videoLengthLabel.anchor(top: userNameLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 4, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
    }
    
}
