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
            let carInFront = car.responseFromSensors(inPositions: [.front]).first
            if carInFront != nil {
                car.pointsPerSecond = Double(arc4random_uniform(UInt32(abs(carInFront!.pointsPerSecond-5)))+40)//???
                let move = SKAction.moveBy(x: 0.0, y: CGFloat(car.pointsPerSecond), duration: 1.0)
                car.removeAction(forKey: "move")
                car.run(SKAction.repeatForever(move), withKey: "move")
            }
            
            if car.wantsToChangeLane {
                if arc4random_uniform(2) == 1 {
                    if car.changeLane(inDirection: .right) == false {
                        if car.changeLane(inDirection: .left) {
                            car.wantsToChangeLane = false
                        }
                    } else {
                        car.wantsToChangeLane = false
                    }
                    car.cantMoveForXTime = 1.0
                } else {
                    if car.changeLane(inDirection: .left) == false {
                        if car.changeLane(inDirection: .right) {
                            car.wantsToChangeLane = false
                        }
                    } else {
                        car.wantsToChangeLane = false
                    }
                    car.cantMoveForXTime = 1.0
                }
                if car.wantsToChangeLane == false {
                    car.pointsPerSecond = Double(arc4random_uniform(40)+50)
                    let move = SKAction.moveBy(x: 0.0, y: CGFloat(car.pointsPerSecond), duration: 1.0)
                    car.removeAction(forKey: "move")
                    car.run(SKAction.repeatForever(move), withKey: "move")
                }
            }
            
            //Diagonal Check
            let right = Set(car.responseFromSensors(inPositions: [.frontRight,.right]).filter({ $0.mindSet != .player }))
            let left = Set(car.responseFromSensors(inPositions: [.frontLeft,.left]).filter({ $0.mindSet != .player }))
            
            if !right.isEmpty && !left.isEmpty {
                var setOfCars = Set([car]).union(right).union(left)
                setOfCars = Set(setOfCars.filter({ $0.cantMoveForXTime <= 0.0 }))//??? and checked in this frame
                laneIsBlocked(byCars: setOfCars)
            }
            
            
            /*//Horizontal Check XXX
     if car.wantsToChangeLane {
     if car.isMoving == false {
     if arc4random_uniform(2) == 1 {
     if car.responseFromSensors(inPositions: [.right]).isEmpty {
     print("changeLane")
     car.wantsToChangeLane = false
     car.change(lane: 1)
     car.cantMoveForXTime = 2
     car.pointsPerSecond *= 0.75
     let move = SKAction.moveBy(x: 0.0, y: CGFloat(car.pointsPerSecond), duration: 1.0)
     car.removeAction(forKey: "move")
     car.run(SKAction.repeatForever(move), withKey: "move")
     } else if car.responseFromSensors(inPositions: [.left]).isEmpty {
     print("changeLane")
     car.wantsToChangeLane = false
     car.change(lane: -1)
     car.cantMoveForXTime = 2
     car.pointsPerSecond *= 0.75
     let move = SKAction.moveBy(x: 0.0, y: CGFloat(car.pointsPerSecond), duration: 1.0)
     car.removeAction(forKey: "move")
     car.run(SKAction.repeatForever(move), withKey: "move")
     }
     } else {
     if car.responseFromSensors(inPositions: [.left]).isEmpty {
     print("changeLane")
     car.wantsToChangeLane = false
     car.change(lane: -1)
     car.cantMoveForXTime = 2
     car.pointsPerSecond *= 0.75
     let move = SKAction.moveBy(x: 0.0, y: CGFloat(car.pointsPerSecond), duration: 1.0)
     car.removeAction(forKey: "move")
     car.run(SKAction.repeatForever(move), withKey: "move")
     } else if car.responseFromSensors(inPositions: [.right]).isEmpty {
     print("changeLane")
     car.wantsToChangeLane = false
     car.change(lane: 1)
     car.cantMoveForXTime = 2
     car.pointsPerSecond *= 0.75
     let move = SKAction.moveBy(x: 0.0, y: CGFloat(car.pointsPerSecond), duration: 1.0)
     car.removeAction(forKey: "move")
     car.run(SKAction.repeatForever(move), withKey: "move")
     }
     }
             car.timeToChangeLane = Double.randomWith2Decimals(inRange: 2..<4)
             }
             }
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
            //randomiseBehaviour(forCar: car)
        }
    }
    
    private func laneIsBlocked(byCars: Set<MVACar>) {
        if  byCars.count > 0 {
        var cars = Array(byCars)
            for car in cars {
                car.cantMoveForXTime = 0.5
            }
        let carToMove = cars.removeLast() //arc4random_uniform(2) == 1 ? cars.remove(at: cars.index(cars.startIndex, offsetBy: 1)):cars.remove(at: cars.index(cars.startIndex, offsetBy: cars.count-1))???
            carToMove.stampIt()
        let rightCars = Set(carToMove.responseFromSensors(inPositions: [.frontRight,.right]).filter({ $0.mindSet != .player }))
        let leftCars = Set(carToMove.responseFromSensors(inPositions: [.frontLeft,.left]).filter({ $0.mindSet != .player }))
            
            let maxLane = carToMove.roadLanePositions.count-1
            
            switch (leftCars.isEmpty,rightCars.isEmpty,carToMove.currentLane) {
            case (false,false,0):
                //on the left and free
                let moved = carToMove.changeLane(inDirection: .right)
                print("on the left and free, moved: \(moved)")
                carToMove.cantMoveForXTime = 2.0
            case (false,false,maxLane):
                //on the right and free
                let moved = carToMove.changeLane(inDirection: .left)
                print("on the right and free, moved: \(moved)")
                carToMove.cantMoveForXTime = 2.0
            case (true,false,0),(false,true,maxLane),(true,true,_):
                print("totallyBlocked")
                carToMove.pointsPerSecond = 150.1//ppS to CGFloat
                let move = SKAction.moveBy(x: 0.0, y: CGFloat(carToMove.pointsPerSecond), duration: 1.0)
                carToMove.removeAction(forKey: "move")
                carToMove.run(SKAction.repeatForever(move), withKey: "move")
                carToMove.wantsToChangeLane = true
                /*
                print("on the left and blocked")
                //on the left blocked from right
                //mostLeftCar(carToMove, blockedFromRightBy: rightCars)
            case (false,true,maxLane):
                print("on the right and blocked")
                //on the right blocked from left
                //mostRightCar(carToMove, blockedFromLeftBy: leftCars)
            case (true,true,_):
                print("totallyBlocked")
                carToMove.pointsPerSecond = 150.1//ppS to CGFloat
                let move = SKAction.moveBy(x: 0.0, y: CGFloat(carToMove.pointsPerSecond), duration: 1.0)
                carToMove.removeAction(forKey: "move")
                carToMove.run(SKAction.repeatForever(move), withKey: "move")
                carToMove.wantsToChangeLane = true
                //laneIsBlocked(byCars: leftCars.union(rightCars))
                 */
            case (false,false,_):
                print("center")
                //carToMove.change(lane: -1)
                carToMove.cantMoveForXTime = 2.0
            case (true,false,_):
                let moved = carToMove.changeLane(inDirection: .left)
                print("center can go left, moved: \(moved)")
                carToMove.cantMoveForXTime = 1.0
            case (false,true,_):
                let moved = carToMove.changeLane(inDirection: .right)
                print("center can go right, moved: \(moved)")
                carToMove.cantMoveForXTime = 1.0
            }
            //centerCar and othe cases
        }
    }
    
    private func mostLeftCar(_ car: MVACar, blockedFromRightBy rightCars: Set<MVACar>) {
        var carsToTheRightOfRightCar = Set<MVACar>()
        for car in rightCars {
            carsToTheRightOfRightCar = carsToTheRightOfRightCar.union(car.responseFromSensors(inPositions: [.frontRight,.right]))
        }
        if !carsToTheRightOfRightCar.isEmpty {
            //blocked again
            laneIsBlocked(byCars: carsToTheRightOfRightCar)
            return
        } else {
            //???
        }
    }
    
    private func mostRightCar(_ car: MVACar, blockedFromLeftBy leftCars: Set<MVACar>) {
        var carsToTheRightOfRightCar = Set<MVACar>()
        for car in leftCars {
            carsToTheRightOfRightCar = carsToTheRightOfRightCar.union(car.responseFromSensors(inPositions: [.frontLeft,.left]))
        }
        if !carsToTheRightOfRightCar.isEmpty {
            //blocked again
            laneIsBlocked(byCars: carsToTheRightOfRightCar)
            return
        } else {
            //???
        }
    }
    
    private func randomiseBehaviour(forCar car: MVACar) {
        if car.cantMoveForXTime <= 0.0 {
            //Lane
            if car.timeToChangeLane <= 0.0 {
                if car.cantMoveForXTime <= 0.0 && car.isMoving == false {
                    if arc4random_uniform(2) == 1 {
                        if car.changeLane(inDirection: .right) == false {
                            _ = car.changeLane(inDirection: .left)
                        }
                        car.cantMoveForXTime = 1.0
                    } else {
                        if car.changeLane(inDirection: .left) == false {
                            _ = car.changeLane(inDirection: .right)
                        }
                        car.cantMoveForXTime = 1.0
                    }
                }
                car.timeToChangeLane = Double.randomWith2Decimals(inRange: 1..<3)
            }
            //Speed
            if car.timeToChangeSpeed <= 0.0 {
                if car.responseFromSensors(inPositions: [.front]).isEmpty {
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
