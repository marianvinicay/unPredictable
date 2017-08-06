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
            let spawnT = abs(MVAConstants.baseSpawnTime-(Double(newValue-1)/2.96))
            if spawnT < 0.6 {
                spawnRate = 0.6
            } else {
                spawnRate = spawnT
            }
        }
    }
    
    var nextMilestone: Int {
        return Int(pow(Double(level), 2.0))
    }
    
    var playerSpeed = MVAConstants.basePlayerSpeed
    
    var spawnRate = MVAConstants.baseSpawnTime
    
    init(level: Int) {
        playerSpeed = MVAConstants.basePlayerSpeed+(50*level)
        spawnRate = MVAConstants.baseSpawnTime*(1-Double(level-1)*0.15)
        self.level = level
    }
}
