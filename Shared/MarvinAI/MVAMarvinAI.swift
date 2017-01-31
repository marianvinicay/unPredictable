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
            car.timeCountdown(deltaT: dTime)
            //Front Check
            if let otherCar = car.carInFront() {
                car.pointsPerSecond = Double(arc4random_uniform(UInt32(otherCar.pointsPerSecond-5))+30)//???
                let move = SKAction.moveBy(x: 0.0, y: CGFloat(car.pointsPerSecond), duration: 1.0)
                car.removeAction(forKey: "move")
                car.run(SKAction.repeatForever(move), withKey: "move")
            }
            
            if car.wantsToChangeLane {
                if car.isMoving == false {
                    if arc4random_uniform(2) == 1 {
                        if car.carsOnRight().isEmpty {
                            car.wantsToChangeLane = false
                            car.change(lane: 1)
                            car.cantMoveForXTime = 1.5
                        }
                    } else {
                        if car.carsOnLeft().isEmpty {
                            car.wantsToChangeLane = false
                            car.change(lane: -1)
                            car.cantMoveForXTime = 1.5
                        }
                    }
                    car.timeToChangeLane = Double.randomWith2Decimals(inRange: 2..<4)
                }
            }
            
            //Diagonal Check
            let right = car.diagonalRight()
            let left = car.diagonalLeft()
            
            if !right.isEmpty && !left.isEmpty {
                //the car is in the center with sides blocked
                /*var xxxSet = Array(right)+Array(left)
                xxxSet.append(car)
                for xxx in xxxSet {
                    xxx.checked = true
                }*/
                //let i = Int(arc4random_uniform(UInt32(xxxSet.count-1)))
                //let cToR = xxxSet[i]
                //if cToR.checked == false {
                    //entities.remove(car)
                    //car.removeFromParent()
                //}
                if car.carInFront() == nil {
                    car.pointsPerSecond = Double(arc4random_uniform(60)+50)//ppS to CGFloat
                    let move = SKAction.moveBy(x: 0.0, y: CGFloat(car.pointsPerSecond), duration: 1.0)
                    car.removeAction(forKey: "move")
                    car.run(SKAction.repeatForever(move), withKey: "move")
                    car.timeToChangeSpeed = Double.randomWith2Decimals(inRange: 2..<4)
                    car.cantMoveForXTime = 0.5
                }
                car.timeToChangeLane = Double.randomWith2Decimals(inRange: 2..<4)
                car.wantsToChangeLane = true
            }
            
            
            /*//Horizontal Check XXX
            let leftCollisions = car.carsOnLeft()
            let rightCollisions = car.carsOnRight()
            print("count",leftCollisions.count,rightCollisions.count)
            if !leftCollisions.isEmpty && !rightCollisions.isEmpty {
                switch  arc4random_uniform(3) {
                case 0:
                    car.pointsPerSecond = Double(arc4random_uniform(100)+80)//ppS to CGFloat
                    let move = SKAction.moveBy(x: 0.0, y: CGFloat(car.pointsPerSecond), duration: 1.0)
                    car.removeAction(forKey: "move")
                    car.run(SKAction.repeatForever(move), withKey: "move")
                case 1:
                    for ocar in leftCollisions {
                    ocar.pointsPerSecond = Double(arc4random_uniform(100)+80)//ppS to CGFloat
                    let move = SKAction.moveBy(x: 0.0, y: CGFloat(ocar.pointsPerSecond), duration: 1.0)
                    ocar.removeAction(forKey: "move")
                    ocar.run(SKAction.repeatForever(move), withKey: "move")
                    }
                case 2:
                    for ocar in rightCollisions {
                    ocar.pointsPerSecond = Double(arc4random_uniform(100)+80)//ppS to CGFloat
                    let move = SKAction.moveBy(x: 0.0, y: CGFloat(ocar.pointsPerSecond), duration: 1.0)
                    ocar.removeAction(forKey: "move")
                    ocar.run(SKAction.repeatForever(move), withKey: "move")
                    }
                default: break
                }
            }*/
            
            //Randomise
            randomiseBehaviour(forCar: car)
        }
    }
    
    private func randomiseBehaviour(forCar car: MVACar) {
        if car.cantMoveForXTime <= 0.0 {
            //Lane
            if car.timeToChangeLane <= 0.0 {
                if car.cantMoveForXTime <= 0.0 && car.isMoving == false {
                    if arc4random_uniform(2) == 1 {
                        if car.carsOnRight().isEmpty {
                            car.change(lane: 1)
                            car.cantMoveForXTime = 1.0
                        }
                    } else {
                        if car.carsOnLeft().isEmpty {
                            car.change(lane: -1)
                            car.cantMoveForXTime = 1.0
                        }
                    }
                }
                car.timeToChangeLane = Double.randomWith2Decimals(inRange: 1..<3)
            }
            //Speed
            if car.timeToChangeSpeed <= 0.0 {
                if car.carInFront() == nil {
                    car.pointsPerSecond = Double(arc4random_uniform(50)+40)//ppS to CGFloat
                    let move = SKAction.moveBy(x: 0.0, y: CGFloat(car.pointsPerSecond), duration: 1.0)
                    car.removeAction(forKey: "move")
                    car.run(SKAction.repeatForever(move), withKey: "move")
                    car.cantMoveForXTime = 0.5
                }
                car.timeToChangeSpeed = Double.randomWith2Decimals(inRange: 1..<2)
            }
        }
    }
}
