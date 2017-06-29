//
//  MVALevels.swift
//  (un)Predictable
//
//  Created by Majo on 27/06/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import Foundation
import CoreGraphics

struct MVALevel {
    var level: Int
    
    var nextMilestone: Int {
        return level+2//Int(pow(Double(level), 2.0))
    }
    
    var playerSpeed: CGFloat {
        return MVAConstants.basePlayerSpeed+CGFloat(50*level)
    }
    
    var spawnRate: Double {
        return MVAConstants.baseSpawnTime*(1-Double(level-1)*0.2)
    }
}
