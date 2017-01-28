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
            entity.doSomethingTime -= dTime
            var collidingCars = (entity as? MVACar)?.nearestCars()
            collidingCars?.removeValue(forKey: .bottomRight)
            collidingCars?.removeValue(forKey: .bottomLeft)
            for (i,rule) in entity.rules.enumerated() {
                switch rule {
                case .constantSpeed:
                    MVAMarvinRuleConstantSpeed.move(entity: entity, withDeltaTime: dTime)
                case .randomSpeed:
                    //Randomize entity speed
                    var entToAvoid = entities
                    entToAvoid.remove(entity)
                    let newEnt = entToAvoid.map { (entity: MVAMarvinEntity) -> MVAArea in
                        let topX = entity.position.x+entity.size.width/2
                        let bottomX = entity.position.x-entity.size.width/2
                        let topY = entity.position.y+entity.size.height/2
                        let bottomY = entity.position.y-entity.size.height/2
                        return MVAArea(xRange: bottomX...topX, yRange: bottomY...topY)
                    }
                    //MVAMarvinRuleConstantSpeed.move(entity: entity, withDeltaTime: dTime, avoid: entToAvoid)
                    if collidingCars?.isEmpty == false {
                        if entity.doSomethingTime <= 0.0 {
                            if arc4random_uniform(2) == 1 {
                                //If there's car in front
                                if (entity as? MVACar)?.isMoving == false {
                                    let leftLaneTOPX = CGPoint(x: entity.position.x-entity.size.width, y: entity.position.y+entity.size.height/2)
                                    let leftLaneBOTTX = CGPoint(x: entity.position.x-entity.size.width, y: entity.position.y-entity.size.height/2)
                                    let rightLaneTOPX = CGPoint(x: entity.position.x+entity.size.width, y: entity.position.y+entity.size.height/2)
                                    let rightLaneBOTTX = CGPoint(x: entity.position.x+entity.size.width, y: entity.position.y-entity.size.height/2)
                                    if newEnt.map({ $0.contains(point: leftLaneTOPX) || $0.contains(point: leftLaneBOTTX) }).contains(true) == false && (entity as? MVACar)?.currentLane != 1 {
                                        (entity as? MVACar)?.change(lane: -1)
                                    } else if newEnt.map({ $0.contains(point: rightLaneTOPX) || $0.contains(point: rightLaneBOTTX) }).contains(true) == false && (entity as? MVACar)?.currentLane != 3 {
                                        (entity as? MVACar)?.change(lane: 1)
                                    }
                                }
                            } else {
                                entity.speed = CGFloat(arc4random_uniform(60)+50)
                            }
                        }
                    }
                default: break
                }
            }
            if entity.doSomethingTime <= 0 {
                entity.doSomethingTime = Double(arc4random_uniform(3)+2)
            }
        }
    }
}
