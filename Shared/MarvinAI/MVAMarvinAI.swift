//
//  MarvinAI.swift
//  (un)Predictable
//
//  Created by Majo on 19/11/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import Foundation
import SpriteKit

class MVAMarvinAI: NSObject {
    var player: MVACarPlayer!
    var playerLives = -1
    var playerBraking = false
    var distanceTraveled = 0.0 //in KM/MI accordingly
    var currentLevel = MVALevel(level: 1)
    var cars = Set<MVACarBot>()
    
    let sound = MVASound()
    let gameCHelper = MVAGameCenterHelper()
    var storeHelper: MVAStore {
        #if os(iOS) || os(tvOS)
        return (UIApplication.shared.delegate as! AppDelegate).inStore
        #elseif os(macOS)
        return (NSApplication.shared.delegate as! AppDelegate).inStore
        #endif
    }
    
    var stop = true
    var updateDist = false
    
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
    private func checkFront(ofCar car: MVACarBot) {
        if car.responseFromSensors(inPositions: [.stop], withPlayer: true).isEmpty == false {
            car.pointsPerSecond = 5
        } else if let carInFront = car.responseFromSensors(inPositions: [.front], withPlayer: true).first {
            let randomiser = car.hasPriority ? 1:arc4random_uniform(2)
            if randomiser == 1 {
                let randDir: MVAPosition = arc4random_uniform(2) == 0 ? .left:.right
                if car.changeLane(inDirection: randDir, AndPlayer: player) == false {
                    let nextDir: MVAPosition = randDir == .left ? .right:.left
                    if car.changeLane(inDirection: nextDir, AndPlayer: player) == false {
                        if car.hasPriority {
                            if carInFront is MVACarBot { freeTheWay(blockedByCars: [carInFront as! MVACarBot]) }
                        } else if carInFront.pointsPerSecond < currentLevel.playerSpeed {
                            let speedDifference = Int(arc4random_uniform(10)+10)
                            car.changeSpeed(carInFront.pointsPerSecond-speedDifference)
                        }
                    }
                }
            } else if carInFront.pointsPerSecond < currentLevel.playerSpeed {
                let speedDifference = Int(arc4random_uniform(10)+10)
                car.changeSpeed(carInFront.pointsPerSecond-speedDifference)
                car.hasPriority = false
            }
        }
    }
    
    private var playerPCS = 0.0
    private var playerEmergencyBrake = 0.0
    
    func checkPCS(withDeltaTime dTime: TimeInterval) -> Bool {
        if playerPCS > 0 {
            playerPCS -= dTime
        }
        if playerEmergencyBrake > 0 {
            playerEmergencyBrake -= dTime
        }
        
        if playerLives > 0 && playerPCS <= 0 {
            if let carInFront = player.responseFromSensors(inPositions: [.stop]).first as? MVACarBot {
                defer {
                    sound.pcsSystem(onNode: player)
                    playerPCS = 0.13
                }
                
                let slowDownPlayer = {
                    self.player.brakeLight(true)
                    self.player.pointsPerSecond = carInFront.pointsPerSecond/2
                    self.playerEmergencyBrake = 2.0
                    self.perform(#selector(self.endPlayerBrakeLight), with: nil, afterDelay: 2.0)
                }
                
                if MVAMemory.gameControls == .swipe {
                    let randDir: MVAPosition = arc4random_uniform(2) == 0 ? .left : .right
                    if player.changeLane(inDirection: randDir, pcsCalling: true) == false {
                        let nextDir: MVAPosition = randDir == .left ? .right : .left
                        if player.changeLane(inDirection: nextDir, pcsCalling: true) == false {
                            slowDownPlayer()
                        }
                    }
                } else {
                    slowDownPlayer()
                }
                return true
            }
        }

        if player.pointsPerSecond < currentLevel.playerSpeed && playerEmergencyBrake <= 0 {//player.responseFromSensors(inPositions: [.stop]).isEmpty && playerEmergencyBrake <= 0 {
            //if player.pointsPerSecond < currentLevel.playerSpeed {
                player.changeSpeed(currentLevel.playerSpeed)
            //}
        }
        return false
    }
    
    @objc func endPlayerBrakeLight() {
        if !playerBraking {
            player.brakeLight(false)
        }
    }
    
    func update(withDeltaTime dTime: TimeInterval) {
        if !stop {
            if updateDist {
                // d = v * t
                let realSpeed = Double(MVAWorldConverter.pointsSpeedToRealWorld(player.pointsPerSecond))
                distanceTraveled += ((realSpeed*dTime)/1000)
            }
            
            cars.forEach { (car: MVACarBot) in
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
    
    private func playerCornered() -> [MVACarBot]? {
        let badCars = player.responseFromSensors(inPositions: [.backLeft,.left,.backRight,.right]).map({ $0 as! MVACarBot }).filter({ $0.hasPriority != true })
        let frontCars = player.responseFromSensors(inPositions: [.front]).map({ $0 as! MVACarBot }).filter({ $0.hasPriority != true })
        if !frontCars.isEmpty && badCars.count >= 1 {
            sound.hornSound(onNode: player)
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
        
        let goodCars = cars.filter({ player.position.y < $0.position.y && $0.cantMoveForTime <= 0 })
        if let carInWay = goodCars.sorted(by: { $0.position.y < $1.position.y }).first {
            if let blockingCars = carsBlockingCar(carInWay) {
                freeTheWay(blockedByCars: blockingCars+[carInWay])
            }
        }
    }
    
    private func carsBlockingCar(_ car: MVACarBot) -> [MVACarBot]? {
        let carFilter: (MVACarBot) -> Bool = { $0.cantMoveForTime <= 0 }
        let rightSide = car.responseFromSensors(inPositions: [.backRight,.right,.frontRight]).map({ $0 as! MVACarBot }).filter(carFilter)
        let leftSide = car.responseFromSensors(inPositions: [.backLeft,.left,.frontLeft]).map({ $0 as! MVACarBot }).filter(carFilter)
        
        switch (leftSide.isEmpty,rightSide.isEmpty,car.currentLane) {
        case (true,false,0):
            //left lane, blocked from right
            var mostRightCars = [MVACarBot]()
            for car in rightSide {
                mostRightCars += car.responseFromSensors(inPositions: [.frontRight,.right,.backRight]).map({ $0 as! MVACarBot }).filter(carFilter)
            }
            if !mostRightCars.isEmpty {
                let combination = rightSide+mostRightCars
                if !combination.map({ $0.hasPriority }).contains(true) {
                    return combination
                }
            }
            
        case (false,true,maxLane):
            //right lane, blocked from left
            var mostLeftCars = [MVACarBot]()
            for car in leftSide {
                mostLeftCars += car.responseFromSensors(inPositions: [.frontLeft,.left,.backLeft]).map({ $0 as! MVACarBot }).filter(carFilter)
            }
            if !mostLeftCars.isEmpty {
                let combination = leftSide+mostLeftCars
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
    
    private func freeTheWay(blockedByCars cars: [MVACarBot]) {
        let carsFreeToMove = cars.filter({ $0.cantMoveForTime <= 0.0 }) //change
        let carIndex = carsFreeToMove.map({ $0.hasPriority }).firstIndex(of: true) ?? Int(arc4random_uniform(UInt32(carsFreeToMove.count)))
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
    
    private func randomiseBehaviour(forCar car: MVACarBot) {
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
