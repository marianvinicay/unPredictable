//
//  MVALevels.swift
//  (un)Predictable
//
//  Created by Majo on 27/06/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import Foundation
import CoreGraphics

class MVALevel {
    var level: Int {
        willSet {
            playerSpeed = MVAConstants.basePlayerSpeed+(50*newValue)
            spawnRate = MVAConstants.baseSpawnTime*(1-Double(newValue-1)*0.06)
        }
    }
    
    var nextMilestone: Int {
        return level+1//Int(pow(Double(level), 2.0))
    }
    
    var playerSpeed = MVAConstants.basePlayerSpeed
    
    var spawnRate = MVAConstants.baseSpawnTime
    
    init(level: Int) {
        self.level = level
    }
}
