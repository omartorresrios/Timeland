//
//  Event.swift
//  ReputationApp
//
//  Created by Omar Torres on 10/01/18.
//  Copyright © 2018 OmarTorres. All rights reserved.
//

import UIKit

class Event {
    
    var duration: TimeInterval
    
    var progress: CGFloat = 0
    var playing: Bool = false
    
    let createdAt: Date = Date()
    
    init(duration: TimeInterval) {
        self.duration = duration
    }
}

