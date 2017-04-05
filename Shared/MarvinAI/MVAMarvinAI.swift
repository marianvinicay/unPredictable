//
//  MarvinAI.swift
//  (un)Predictable
//
//  Created by Majo on 19/11/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import Foundation
import SpriteKit

extension Set {
    var isFull: Bool {
        get {
            return !self.isEmpty
        }
    }
}

class MVAMarvinAI {
    var player: MVACar!
    var cars = Set<MVACar>()
    
    var checkTime = 0.0
    
    func update(withDeltaTime dTime: TimeInterval) {
        if checkTime <= 0.0 {
            checkTime = 0.5
            checkJam()
            //let pLane = player.currentLane
            //checkJam(onLane: pLane!)
        } else {
            checkTime -= dTime
        }
        
        for car in cars {
            car.timeCountdown(deltaT: dTime)
            //car in-front (blocked front of car)
            if let carInFront = car.responseFromSensors(inPositions: [.front]).first {
                //if car.getOutOfTheWay {
                //    carInFront.getOutOfTheWay = true
                //} else {
                if car.canPerformManeuver && arc4random_uniform(2) == 1 {
                    if car.changeLane(inDirection: .left) == false {
                        if car.changeLane(inDirection: .right) == false {
                            let speedDifference = CGFloat(arc4random_uniform(10)+10)
                            car.changeSpeed(carInFront.pointsPerSecond-speedDifference, durationOfChange: 1.0)
                        }
                    }
                } else if car.canPerformManeuver {
                    let speedDifference = CGFloat(arc4random_uniform(10)+10)
                    car.changeSpeed(carInFront.pointsPerSecond-speedDifference, durationOfChange: 1.0)//???
                }
                //}
            }
            
            /*if car.getOutOfTheWay {
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
            }*/
            
            if car.hasPriority == false && car.pointsPerSecond == 200.0 {
                car.changeSpeed(CGFloat(arc4random_uniform(40)+50), durationOfChange: 1.0)
            }
            
            //Randomise
            //randomiseBehaviour(forCar: car)
        }
    }
    
    private func checkJam(withCars mCrs: Set<MVACar>) {
        //var myCars = mCrs
        var badApples = [MVACar]()
        for car in cars {
            if !car.wasChecked {
                //if is car blocked? !!!! take current lane into account
                //check lane
                badApples += carsBlockingCar(car).filter({ $0.mindSet != .player })//return Set -> choose one member and do smt
            }
        }
        for car in cars {
            car.wasChecked = false
        }
    }
    
    private func carsBlockingCar(_ car: MVACar) -> Set<MVACar> {
        let leftF = car.responseFromSensors(inPositions: [.frontLeft])
        let leftC = car.responseFromSensors(inPositions: [.left])
        let leftB = car.responseFromSensors(inPositions: [.backLeft])
        let left = leftF.union(leftC).union(leftB)
        let rightF = car.responseFromSensors(inPositions: [.frontRight])
        let rightC = car.responseFromSensors(inPositions: [.right])
        let rightB = car.responseFromSensors(inPositions: [.backRight])
        let right = rightF.union(rightC).union(rightB)
        switch car.currentLane {
        case 0:
            if right.isFull {
                //right consists of middle cars -> check them
                var badCars = Set<MVACar>()
                for car in right {
                    badCars = badCars.union(carsBlockingCar(car))
                }
                badCars.remove(car)//???
                for car in badCars {
                    car.wasChecked = true
                }
                return badCars
            }
        case 2:
            if left.isFull {
                //left consists of middle cars -> check them
                var badCars = Set<MVACar>()
                for car in left {
                    badCars = badCars.union(carsBlockingCar(car))
                }
                badCars.remove(car)//???
                for car in badCars {
                    car.wasChecked = true
                }
                return badCars
            }
        default:
            if left.isFull && right.isFull {
                //center car blocked from sides
                let badCars = left.union(right)
                for car in badCars {
                    car.wasChecked = true
                }
                return badCars
            }
        }
        return []
    }
    
    private func resolveCars(_ badCars: [MVACar]) {// return true/false
        let randNum = Int(arc4random_uniform(UInt32(badCars.count-1)))
        if let randomIndex = badCars.index(badCars.startIndex, offsetBy: randNum, limitedBy: badCars.endIndex) {
            /*if badCars[randomIndex].changeLane(inDirection: .right) == false {
                if badCars[randomIndex].changeLane(inDirection: .left) == false {
                    //badCars[randomIndex].changeSpeed(200, durationOfChange: 1)
                }
            }*/
        }
    }
    
    private func checkJam() {
        let lane = player.currentLane
        let carsInWay = cars.filter({ $0.currentLane == lane && player.position.y < $0.position.y })
        if let carInWay = carsInWay.sorted(by: { $0.position.y < $1.position.y }).first { //???
            let rightSide = carInWay.responseFromSensors(inPositions: [.backRight,.right,.frontRight]).filter({ $0 != player })//&& $0.cantMoveForXTime <= 0.0 }
            let leftSide = carInWay.responseFromSensors(inPositions: [.backLeft,.left,.frontLeft]).filter({ $0 != player })
            let maxLane = carInWay.roadLanePositions.count-1
            switch (leftSide.isEmpty,rightSide.isEmpty,carInWay.currentLane) {
            case (false,false,_):
                //center lane, blocked from sides
                print("center")
                freeTheWay(blockedByCars: rightSide+leftSide+[carInWay]) // + car in centre ???
                /*if carInWay.isFreeToMove() {
                    carInWay.getOutOfTheWay = true
                } else {
                    for car in rightSide.union(leftSide).filter({ $0.isFreeToMove() }) {
                        car.getOutOfTheWay = true
                    }
                }*/
            case (true,false,0):
                //add most right lane !!!
                //left lane, blocked from right
                var mostRightCars = Set<MVACar>()
                for car in rightSide {
                    //mostRightCars.union(carsBlockingCar(car))???
                    mostRightCars = mostRightCars.union(car.responseFromSensors(inPositions: [.frontRight,.right,.backRight]))
                }
                freeTheWay(blockedByCars: rightSide+Array(mostRightCars))
                /*if lanesBlocked(byMostLeftCar: carInWay) {
                    if carInWay.isFreeToMove() {
                        carInWay.getOutOfTheWay = true
                    } else {
                        for car in rightSide.filter({ $0.isFreeToMove() }) {
                            car.getOutOfTheWay = true
                        }
                    }
                }*/
            case (false,true,maxLane):
                //right lane, blocked from left
                var mostLeftCars = Set<MVACar>()
                for car in leftSide {
                    //mostRightCars.union(carsBlockingCar(car))???
                    mostLeftCars = mostLeftCars.union(car.responseFromSensors(inPositions: [.frontLeft,.left,.backLeft]))
                }
                freeTheWay(blockedByCars: leftSide+Array(mostLeftCars))
                /*if lanesBlocked(byMostRightCar: carInWay) {
                    if carInWay.isFreeToMove() {
                        carInWay.getOutOfTheWay = true
                    } else {
                        for car in leftSide.filter({ $0.isFreeToMove() }) {
                            car.getOutOfTheWay = true
                        }
                    }
                }*/
            default: break
            }
            for car in leftSide+rightSide {
                //car.cantMoveForXTime = 0.5
            }
        }
    }
    
    private func freeTheWay(blockedByCars cars: [MVACar]) {
        let carsFreeToMove = cars.filter({ $0.freeToMove().isEmpty == false })
        let randomIndex = Int(arc4random_uniform(UInt32(carsFreeToMove.count)))
        if let badCar = carsFreeToMove[safe: randomIndex] {
            //badCar.hasPriority = true
            let movePositions = badCar.freeToMove()
            badCar.hasPriority = true
            badCar.stampIt()
            //randomise ˇˇˇ ???
            if movePositions.contains(.left) {
                _ = badCar.changeLane(inDirection: .left)
                badCar.hasPriority = false
            } else if movePositions.contains(.right) {
                _ = badCar.changeLane(inDirection: .right)
                badCar.hasPriority = false
            } else {//if contains .front ???
                badCar.changeSpeed(200, durationOfChange: 1.0)
                //badCar.hasPriority = false
            }
            // no more 'collisions' completion -> hasPriority = false
            
        /*if arc4random_uniform(2) == 1 {
            if badCar.changeLane(inDirection: .right) == false {
                if badCar.changeLane(inDirection: .left) {
                    badCar.hasPriority = false
                } else {
                    badCar.changeSpeed(200, durationOfChange: 1.0)
                }
            } else {
                badCar.hasPriority = false
            }
            badCar.cantMoveForXTime = 1.0
        } else {
            if badCar.changeLane(inDirection: .left) == false {
                if badCar.changeLane(inDirection: .right) {
                    badCar.hasPriority = false
                } else {
                    badCar.changeSpeed(200, durationOfChange: 1.0)
                }
            } else {
                badCar.hasPriority = false
            }
            badCar.cantMoveForXTime = 1.0
        }*/
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
                    car.changeSpeed(CGFloat(arc4random_uniform(50)+40), durationOfChange: 1.0)//ppS to CGFloat
                    car.cantMoveForXTime = 0.5
                }
                car.timeToChangeSpeed = Double.randomWith2Decimals(inRange: 1..<2)
            }
        }
    }
}
