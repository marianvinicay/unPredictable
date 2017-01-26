//
//  MarvinAI.swift
//  (un)Predictable
//
//  Created by Majo on 19/11/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import Foundation
import SpriteKit

class MVAMarvinAI {
    var entities = Set<MVAMarvinEntity>()
    
    func update(withDeltaTime dTime: TimeInterval) {
        for entity in entities {
            for (i,rule) in entity.rules.enumerated() {
                switch rule {
                case .constantSpeed: MVAMarvinRuleConstantSpeed.move(entity: entity, withDeltaTime: dTime)
                case .randomSpeed:
                    //Randomize entity speed
                    MVAMarvinRuleConstantSpeed.move(entity: entity, withDeltaTime: dTime, avoid: entities)
                default: break
                }
            }
        }
    }
}
