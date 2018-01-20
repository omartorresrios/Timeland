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
        label.textColor = .white
        label.backgroundColor = .clear
        label.layer.shadowOffset = CGSize(width: 0, height: 0)
        label.layer.shadowOpacity = 1
        label.layer.shadowRadius = 6
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    var url: URL?
    
    let videoLengthLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.backgroundColor = .clear
        label.layer.shadowOffset = CGSize(width: 0, height: 0)
        label.layer.shadowOpacity = 1
        label.layer.shadowRadius = 6
        label.font = UIFont.systemFont(ofSize: 12)
        label.text = "0:00"
        return label
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
