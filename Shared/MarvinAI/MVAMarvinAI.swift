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
    var distanceTraveled = 0.0 //in KM
    var currentLevel = MVALevel(level: 1)
    var cars = Set<MVACar>()
    var lanePositions = [Int:CGFloat]()
    
    private var checkTime = 0.0
    
    private func checkFront(ofCar car: MVACar) {
        //car in-front (blocked front of car)
        //guard let carInFront = car.responseFromSensors(inPositions: [.front]).first else { return }
        if car.responseFromSensors(inPositions: [.stop]).isEmpty == false {
            car.changeSpeed(0)
        } else if let carInFront = car.responseFromSensors(inPositions: [.front]).first {
            let randomiser = car.hasPriority ? 1:arc4random_uniform(2)
            if randomiser == 1 {
                let randDir: MVAPosition = arc4random_uniform(2) == 0 ? .left:.right
                if car.changeLane(inDirection: randDir, withLanePositions: lanePositions, AndPlayer: player) == false {
                    let nextDir: MVAPosition = randDir == .left ? .right:.left
                    if car.changeLane(inDirection: nextDir, withLanePositions: lanePositions, AndPlayer: player) == false {
                        if car.hasPriority && carInFront.mindSet != .player {
                            freeTheWay(blockedByCars: [carInFront])
                            /*carInFront.hasPriority = true
                            if carInFront.pointsPerSecond != currentLevel.playerSpeed {
                                carInFront.priorityTime = MVAConstants.priorityTime
                                car.priorityTime = MVAConstants.priorityTime
                                carInFront.changeSpeed(currentLevel.playerSpeed)
                            }*/
                        } else if carInFront.pointsPerSecond < player.pointsPerSecond {
                            let speedDifference = Int(arc4random_uniform(10)+10)
                            car.changeSpeed(carInFront.pointsPerSecond-speedDifference)
                        }
                    }
                }
            } else if carInFront.pointsPerSecond < player.pointsPerSecond {
                let speedDifference = Int(arc4random_uniform(10)+10)
                car.changeSpeed(carInFront.pointsPerSecond-speedDifference)
                car.hasPriority = false
            }
        }
    }
        
    func update(withDeltaTime dTime: TimeInterval) {
        // d = v * t
        //print((Double(player.pointsPerSecond/2)*dTime/1000),(Double(player.pointsPerSecond/2)*dTime/1000).roundTo(NDecimals: 3))
        let realSpeed = Double(player.pointsPerSecond/5) //in KM/H
        distanceTraveled += (realSpeed*dTime.roundTo(NDecimals: 3)/1000).roundTo(NDecimals: 3)
        
        if player.changingSpeed {
            player.smoothSpeedChange()//???
        }
        
        cars.forEach { (car: MVACar) in
            car.timeCountdown(deltaT: dTime)

            //car in-front (blocked front of car)
            checkFront(ofCar: car)
            
            if car.hasPriority {// free the way -> change lane
                if carsBlockingCar(car)?.isEmpty == true {
                    car.hasPriority = false
                    //no priority ???
                    car.changeSpeed(MVAConstants.baseBotSpeed)
                } else {
                    freeTheWay(blockedByCars: [car])
                }
            } else if car.hasPriority == false && car.pointsPerSecond == currentLevel.playerSpeed {
                car.changeSpeed(MVAConstants.baseBotSpeed)
            }
            
            //Randomiser
            if car.cantMoveForTime <= 0 && car.timeToRandomise <= 0 && !car.hasPriority {
                randomiseBehaviour(forCar: car)
                car.timeToRandomise = Double.randomWith2Decimals(inRange: 1..<3)
            }
        }
        
        
        if checkTime <= 0.0 {
            checkTime = 0.5
            checkJam()
        } else {
            checkTime -= dTime
        }
    }
    
    private func playerCornered() -> [MVACar]? {
        let badCars = player.responseFromSensors(inPositions: [.backLeft,.left,.backRight,.right])//???.frontR/L
        let frontCars = player.responseFromSensors(inPositions: [.front])
        if !frontCars.isEmpty && badCars.count >= 1 { //???
            return Array(badCars.union(frontCars))
        } else {
            return nil
        }
    }
    
    private func checkJam() {
        let pLane = player.currentLane
        if pLane == 0 || pLane == 2 {
            if let badCars = playerCornered() {
                freeTheWay(blockedByCars: badCars)
            }
            return
            //special free the way for center
        }
        
        //if let carInWay = carsInFront.sorted(by: { $0.position.y < $1.position.y }).first {
        if let carInWay = cars.filter({ /*$0.currentLane == pLane &&*/ player.position.y < $0.position.y && $0.cantMoveForTime <= 0 }).sorted(by: { $0.position.y < $1.position.y }).first {
            if let blockingCars = carsBlockingCar(carInWay) {
                freeTheWay(blockedByCars: blockingCars+[carInWay])
            }
            
        }
    }
    
    private func carsBlockingCar(_ car: MVACar) -> [MVACar]? {
        let carFilter: (MVACar) -> Bool = { $0.mindSet != .player && $0.cantMoveForTime <= 0 }
        let rightSide = car.responseFromSensors(inPositions: [.backRight,.right,.frontRight]).filter(carFilter)
        let leftSide = car.responseFromSensors(inPositions: [.backLeft,.left,.frontLeft]).filter(carFilter)
        let maxLane = lanePositions.count-1
        
        switch (leftSide.isEmpty,rightSide.isEmpty,car.currentLane) {
        case (true,false,0):
            //left lane, blocked from right
            var mostRightCars = Set<MVACar>()
            for car in rightSide {
                mostRightCars = mostRightCars.union(car.responseFromSensors(inPositions: [.frontRight,.right,.backRight]).filter(carFilter))
            }
            if !mostRightCars.isEmpty {
                let combination = rightSide+Array(mostRightCars)
                if !combination.map({ $0.hasPriority }).contains(true) {
                    return combination
                }
            }
            
        case (false,true,maxLane):
            //right lane, blocked from left
            var mostLeftCars = Set<MVACar>()
            for car in leftSide {
                mostLeftCars = mostLeftCars.union(car.responseFromSensors(inPositions: [.frontLeft,.left,.backLeft]).filter(carFilter))
            }
            if !mostLeftCars.isEmpty {
                let combination = leftSide+Array(mostLeftCars)
                if !combination.map({ $0.hasPriority }).contains(true) {
                    return combination
                }
            }
            
        case (false,false,_):
            //center lane, blocked from sides
            let combination = rightSide+leftSide
            if !combination.map({ $0.hasPriority }).contains(true) {
                return combination
            }
        default: break
        }
        
        return nil
    }
    
    private func freeTheWay(blockedByCars cars: [MVACar]) {
        let carsFreeToMove = cars.filter({ $0.mindSet != .player })
        let carIndex = carsFreeToMove.map({ $0.hasPriority }).index(of: true) ?? Int(arc4random_uniform(UInt32(carsFreeToMove.count)))
        if let badCar = carsFreeToMove[safe: carIndex] {
            let randDir: MVAPosition = arc4random_uniform(2) == 0 ? .left:.right
            let oppositeDir: MVAPosition = randDir == .left ? .right:.left
            
            if badCar.changeLane(inDirection: randDir, withLanePositions: lanePositions, AndPlayer: player) {
                badCar.hasPriority = false
            } else if badCar.changeLane(inDirection: oppositeDir, withLanePositions: lanePositions, AndPlayer: player) {
                badCar.hasPriority = false
            } else if badCar.hasPriority == false {
                if (badCar.position.y < player.position.y-player.size.height) == false && badCar.noPriorityForTime <= 0 {
                    badCar.changeSpeed(currentLevel.playerSpeed)
                    badCar.priorityTime = MVAConstants.priorityTime
                    badCar.hasPriority = true
                }
            }
        }
    }
    
    private func randomiseBehaviour(forCar car: MVACar) {
        //go into player's lane in more difficult level !!
        switch arc4random_uniform(2) {
        case 0 where car.currentLane != player.currentLane:
            let firstDir: MVAPosition = arc4random_uniform(2) == 1 ? .right:.left
            let oppositeDir: MVAPosition = firstDir == .right ? .left:.right
            if car.changeLane(inDirection: firstDir, withLanePositions: lanePositions, AndPlayer: player) == false {
                _ = car.changeLane(inDirection: oppositeDir, withLanePositions: lanePositions, AndPlayer: player)
            }
        case 2:
            let firstDir: MVAPosition = arc4random_uniform(2) == 1 ? .left:.right
            let oppositeDir: MVAPosition = firstDir == .right ? .left:.right
            if car.changeLane(inDirection: firstDir, withLanePositions: lanePositions, AndPlayer: player) == false {
                _ = car.changeLane(inDirection: oppositeDir, withLanePositions: lanePositions, AndPlayer: player)
            }
        case 1:
            car.changeSpeed(MVAConstants.baseBotSpeed)
        default: break
        }
    }
}

