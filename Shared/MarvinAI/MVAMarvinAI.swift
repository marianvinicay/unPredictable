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
    var distanceTraveled = 0.0 //in KM/MI accordingly
    var currentLevel = MVALevel(level: 1)
    var cars = Set<MVACar>()
    let gameCHelper = MVAGameCenterHelper()
    let healthKHelper = MVAHealthKit()
    let storeHelper = MVAStore()
    
    var stop = false
    
    private var checkTime = 0.3
    
    func reset() {
        player.removeFromParent()
        player = nil
        distanceTraveled = 0.0
        currentLevel.level = 1
        cars.forEach({
            $0.removeFromParent()
            cars.remove($0)
        })
        stop = false
    }
    
    ///car in-front (blocked front of car)
    private func checkFront(ofCar car: MVACar) {
        if car.responseFromSensors(inPositions: [.stop]).isEmpty == false {
            car.changeSpeed(0)
        } else if let carInFront = car.responseFromSensors(inPositions: [.front]).first {
            let randomiser = car.hasPriority ? 1:arc4random_uniform(2)
            if randomiser == 1 {
                let randDir: MVAPosition = arc4random_uniform(2) == 0 ? .left:.right
                if car.changeLane(inDirection: randDir, AndPlayer: player) == false {
                    let nextDir: MVAPosition = randDir == .left ? .right:.left
                    if car.changeLane(inDirection: nextDir, AndPlayer: player) == false {
                        if car.hasPriority && carInFront.mindSet != .player {
                            freeTheWay(blockedByCars: [carInFront])
                        } else if carInFront.pointsPerSecond != currentLevel.playerSpeed {
                            let speedDifference = Int(arc4random_uniform(10)+10)
                            car.changeSpeed(carInFront.pointsPerSecond-speedDifference)
                        }
                    }
                }
            } else if carInFront.pointsPerSecond != currentLevel.playerSpeed {
                let speedDifference = Int(arc4random_uniform(10)+10)
                car.changeSpeed(carInFront.pointsPerSecond-speedDifference)
                car.hasPriority = false
            }
        }
    }
    
    func update(withDeltaTime dTime: TimeInterval) {
        if !stop {
            // d = v * t
            let realSpeed = Double(MVAWorldConverter.pointsSpeedToRealWorld(player.pointsPerSecond))
            distanceTraveled += ((realSpeed*dTime)/1000)
            
            cars.forEach { (car: MVACar) in
                if car.pointsPerSecond != 0 {
                    car.timeCountdown(deltaT: dTime)
                    
                    //car in-front (blocked front of car)
                    checkFront(ofCar: car)
                    
                    if car.hasPriority {
                        if carsBlockingCar(car)?.isEmpty == true || player.position.y < car.position.y {
                            car.hasPriority = false
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
            }
            
            DispatchQueue.main.async {
                if self.checkTime <= 0.0 {
                    self.checkTime = 0.3
                    self.checkJam()
                } else {
                    self.checkTime -= dTime
                }
            }
        }
    }
    
    private func playerCornered() -> [MVACar]? {
        let badCars = player.responseFromSensors(inPositions: [.backLeft,.left,.backRight,.right]).filter({ $0.hasPriority != true })//???
        let frontCars = player.responseFromSensors(inPositions: [.front]).filter({ $0.hasPriority != true })
        if !frontCars.isEmpty && badCars.count >= 1 { //???
            return badCars+frontCars
        } else {
            return nil
        }
    }
    
    private func checkJam() {
        let pLane = player.currentLane
        if pLane == 0 || pLane == maxLane {
            if let badCars = playerCornered() {
                freeTheWay(blockedByCars: badCars)
            }
            return
        }
        
        if let carInWay = cars.filter({ player.position.y < $0.position.y && $0.cantMoveForTime <= 0 }).sorted(by: { $0.position.y < $1.position.y }).first {
            if let blockingCars = carsBlockingCar(carInWay) {
                freeTheWay(blockedByCars: blockingCars+[carInWay])
            }
        }
    }
    
    private func carsBlockingCar(_ car: MVACar) -> [MVACar]? {
        let carFilter: (MVACar) -> Bool = { $0.mindSet != .player && $0.cantMoveForTime <= 0 }
        let rightSide = car.responseFromSensors(inPositions: [.backRight,.right,.frontRight]).filter(carFilter)
        let leftSide = car.responseFromSensors(inPositions: [.backLeft,.left,.frontLeft]).filter(carFilter)
        
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
            
            if badCar.changeLane(inDirection: randDir, AndPlayer: player) {
                badCar.hasPriority = false
            } else if badCar.changeLane(inDirection: oppositeDir, AndPlayer: player) {
                badCar.hasPriority = false
            } else if badCar.hasPriority == false {
                if (badCar.position.y < player.position.y-player.size.height) == false && badCar.noPriorityForTime <= 0 {
                    badCar.changeSpeed(currentLevel.playerSpeed+Int(arc4random_uniform(10)+10))
                    badCar.priorityTime = MVAConstants.priorityTime
                    badCar.hasPriority = true
                }
            }
        }
    }
    
    private func randomiseBehaviour(forCar car: MVACar) {
        if car.currentLane == player.currentLane && arc4random_uniform(2) == 0 {//give way to player
            let firstDir: MVAPosition = arc4random_uniform(2) == 1 ? .left:.right
            let oppositeDir: MVAPosition = firstDir == .right ? .left:.right
            if car.changeLane(inDirection: firstDir, AndPlayer: player) == false {
                _ = car.changeLane(inDirection: oppositeDir, AndPlayer: player)
            }
        } else if car.currentLane != player.currentLane {//go into player's lane
            let laneDiff = player.currentLane-car.currentLane
            let myDir: MVAPosition = laneDiff > 0 ? .right:.left
            _ = car.changeLane(inDirection: myDir, AndPlayer: player)
        }
        if arc4random_uniform(2) == 1 {
            car.changeSpeed(MVAConstants.baseBotSpeed)
        }
    }
}

public var lanePositions = [Int:Int]()
public var maxLane: Int {
    return lanePositions.count-1
}
