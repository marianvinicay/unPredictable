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
    var player: MVACar!
    var cars = Set<MVACar>()
    
    var checkTime = 0.0
    
    func update(withDeltaTime dTime: TimeInterval) {
        for car in cars {
            car.isFirst = false
        }
        if checkTime <= 0.0 {
            checkTime = 0.5
            let pLane = player.currentLane
            checkJam(onLane: pLane!)
        } else {
            checkTime -= dTime
        }
        
        for car in cars {
            car.timeCountdown(deltaT: dTime)
            //Front Check
            let carInFront = car.responseFromSensors(inPositions: [.front]).first
            if carInFront != nil {
                if car.getOutOfTheWay {
                    carInFront!.getOutOfTheWay = true
                } else {
                    car.changeSpeed(CGFloat(arc4random_uniform(UInt32(abs(carInFront!.pointsPerSecond-5)))+40))//???
                }
            }
            
            if car.getOutOfTheWay {
                if carInFront == nil {
                    //speed up
                    car.changeSpeed(200)
                    print("speedUp",car.pointsPerSecond)
                }
                if arc4random_uniform(2) == 1 {
                    if car.changeLane(inDirection: .right) == false {
                        if car.changeLane(inDirection: .left) {
                            car.getOutOfTheWay = false
                        }
                    } else {
                        car.getOutOfTheWay = false
                    }
                    car.cantMoveForXTime = 1.0
                } else {
                    if car.changeLane(inDirection: .left) == false {
                        if car.changeLane(inDirection: .right) {
                            car.getOutOfTheWay = false
                        }
                    } else {
                        car.getOutOfTheWay = false
                    }
                    car.cantMoveForXTime = 1.0
                }
                if car.getOutOfTheWay == false {
                    car.changeSpeed(CGFloat(arc4random_uniform(40)+50))
                }
            }
            
            /*
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
            }*/
            
            //Randomise
            //randomiseBehaviour(forCar: car)
        }
    }
    
    private func checkJam(onLane lane: Int) {
        let carsOnLeft = cars.filter({ $0.currentLane == (lane-1) && player.position.y < $0.position.y }).count
        let carsInWay = cars.filter({ $0.currentLane == lane && player.position.y < $0.position.y })
        let carsOnRight = cars.filter({ $0.currentLane == (lane+1) && player.position.y < $0.position.y }).count
        if let carInWay = carsInWay.sorted(by: { $0.position.y < $1.position.y }).first { //???
            carInWay.isFirst = true
            let rightSide = carInWay.responseFromSensors(inPositions: [.backRight,.right,.frontRight])
            let leftSide = carInWay.responseFromSensors(inPositions: [.backLeft,.left,.frontLeft])
            let maxLane = carInWay.roadLanePositions.count-1
            switch (leftSide.isEmpty,rightSide.isEmpty,carInWay.currentLane) {
            case (false,false,_):
                //center lane
                if carInWay.isFreeToMove() {
                    carInWay.getOutOfTheWay = true
                } else {
                    for car in rightSide.union(leftSide).filter({ $0.isFreeToMove() }) {
                        car.getOutOfTheWay = true
                    }
                }
            case (true,false,0):
                //left lane
                if lanesBlocked(byMostLeftCar: carInWay) {
                    if carInWay.isFreeToMove() {
                        carInWay.getOutOfTheWay = true
                    } else {
                        for car in rightSide.filter({ $0.isFreeToMove() }) {
                            car.getOutOfTheWay = true
                        }
                    }
                }
            case (false,true,maxLane):
                //right lane
                if lanesBlocked(byMostRightCar: carInWay) {
                    if carInWay.isFreeToMove() {
                        carInWay.getOutOfTheWay = true
                    } else {
                        for car in leftSide.filter({ $0.isFreeToMove() }) {
                            car.getOutOfTheWay = true
                        }
                    }
                }
            default: break
            }
            for car in leftSide.union(rightSide) {
                car.cantMoveForXTime = 1.0
            }
        }
    }
    
    /*private func laneIsBlocked(byCars: Set<MVACar>) {
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
    */
    private func lanesBlocked(byMostLeftCar leftCar: MVACar) -> Bool {
        for car in leftCar.responseFromSensors(inPositions: [.frontRight,.right,.backRight]) {
            if car.responseFromSensors(inPositions: [.frontRight,.right,.backRight,.back]).isEmpty == false {
                return true
            }
        }
        return false
    }
    
    private func lanesBlocked(byMostRightCar rightCar: MVACar) -> Bool {
        for car in rightCar.responseFromSensors(inPositions: [.frontLeft,.left,.backLeft]) {
            if car.responseFromSensors(inPositions: [.frontLeft,.left,.backLeft,.back]).isEmpty == false {
                return true
            }
        }
        return false
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
                    car.changeSpeed(CGFloat(arc4random_uniform(50)+40))//ppS to CGFloat
                    car.cantMoveForXTime = 0.5
                }
                car.timeToChangeSpeed = Double.randomWith2Decimals(inRange: 1..<2)
            }
        }
    }
}
