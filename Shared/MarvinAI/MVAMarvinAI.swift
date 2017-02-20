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
        
        //1. player must stay in lane (blocked front & sides)
        if let blockingCars = player.mustStayInCurrentLane() {
            for car in blockingCars {
                //!!!
                car.getOutOfTheWay = true
            }
        }
        
        for car in cars {
            car.timeCountdown(deltaT: dTime)
            //2. car in-front (blocked front of car in same lane)
            let carInFront = car.responseFromSensors(inPositions: [.front]).first
            if carInFront != nil {
                if car.getOutOfTheWay {
                    carInFront!.getOutOfTheWay = true
                } else {
                    car.changeSpeed(CGFloat(arc4random_uniform(UInt32(abs(carInFront!.pointsPerSecond-5)))+40), durationOfChange: 1.0)//???
                }
            }
            
            if car.getOutOfTheWay {
                if player.currentLane != car.currentLane {
                    car.getOutOfTheWay = false
                }

                if arc4random_uniform(2) == 1 {
                    if car.changeLane(inDirection: .right) == false {
                        if car.changeLane(inDirection: .left) {
                            car.getOutOfTheWay = false
                        } else {
                            car.changeSpeed(200, durationOfChange: 1.0)
                        }
                    } else {
                        car.getOutOfTheWay = false
                    }
                    car.cantMoveForXTime = 1.0
                } else {
                    if car.changeLane(inDirection: .left) == false {
                        if car.changeLane(inDirection: .right) {
                            car.getOutOfTheWay = false
                        } else {
                            car.changeSpeed(200, durationOfChange: 1.0)
                        }
                    } else {
                        car.getOutOfTheWay = false
                    }
                    car.cantMoveForXTime = 1.0
                }
                if car.getOutOfTheWay == false {
                    car.changeSpeed(CGFloat(arc4random_uniform(40)+50), durationOfChange: 1.0)
                }
            }
            
            //Randomise
            //randomiseBehaviour(forCar: car)
        }
    }
    
    //3. Check jam (blocked lane smwhere/can't passthrough)
    private func checkJam(onLane lane: Int) {
        //let carsOnLeft = cars.filter({ $0.currentLane == (lane-1) && player.position.y < $0.position.y }).count
        let carsInWay = cars.filter({ $0.currentLane == lane && player.position.y < $0.position.y })
        //let carsOnRight = cars.filter({ $0.currentLane == (lane+1) && player.position.y < $0.position.y }).count
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
                    car.changeSpeed(CGFloat(arc4random_uniform(50)+40), durationOfChange: 1.0)//ppS to CGFloat
                    car.cantMoveForXTime = 0.5
                }
                car.timeToChangeSpeed = Double.randomWith2Decimals(inRange: 1..<2)
            }
        }
    }
}
