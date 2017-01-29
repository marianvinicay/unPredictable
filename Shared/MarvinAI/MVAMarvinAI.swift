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
    var entities = Set<MVACar>()
    
    func update(withDeltaTime dTime: TimeInterval) {
        for car in entities {
            car.doSomethingTime -= dTime
            if let otherCar = car.carInFront() {
                car.pointsPerSecond = Double(arc4random_uniform(UInt32(otherCar.pointsPerSecond))+30)
                let move = SKAction.moveBy(x: 0.0, y: CGFloat(car.pointsPerSecond), duration: 1.0)
                car.removeAction(forKey: "move")
                car.run(SKAction.repeatForever(move), withKey: "move")
            }
            if car.doSomethingTime <= 0.0 {
                if arc4random_uniform(2) == 1 {
                    //If there's car in front
                    if car.isMoving == false {
                        if arc4random_uniform(2) == 1 {
                            if car.carsOnRight().isEmpty {
                                car.change(lane: 1)
                            }
                        } else {
                            if car.carsOnLeft().isEmpty {
                                car.change(lane: -1)
                            }
                        }
                    }
                } else {
                    if car.carInFront() == nil {
                        car.pointsPerSecond = Double(arc4random_uniform(60)+50)//ppS to CGFloat
                        let move = SKAction.moveBy(x: 0.0, y: CGFloat(car.pointsPerSecond), duration: 1.0)
                        car.removeAction(forKey: "move")
                        car.run(SKAction.repeatForever(move), withKey: "move")
                    }
                }
            }
            if car.doSomethingTime <= 0 {
                car.doSomethingTime = Double(arc4random_uniform(3)+2)
            }
        }
    }
}
