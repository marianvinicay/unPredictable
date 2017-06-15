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
    
    private var checkTime = 0.0
    
    private func checkFront(ofCar car: MVACar) {
        //car in-front (blocked front of car)
        if let carInFront = car.responseFromSensors(inPositions: [.front]).filter({ $0.mindSet != .player }).first {
            if arc4random_uniform(2) == 1 {
                //RANDOMISE
                if car.changeLane(inDirection: .left) == false {
                    if car.changeLane(inDirection: .right) == false {
                        let speedDifference = CGFloat(arc4random_uniform(10)+10)
                        car.changeSpeed(carInFront.pointsPerSecond-speedDifference, durationOfChange: 1.0)
                    }
                }
            } else {
                let speedDifference = CGFloat(arc4random_uniform(10)+10)
                car.changeSpeed(carInFront.pointsPerSecond-speedDifference, durationOfChange: 1.0)//???
            }
        }
    }
    
    func update(withDeltaTime dTime: TimeInterval) {
        if checkTime <= 0.0 {
            checkTime = 0.5
            checkJam()
        } else {
            checkTime -= dTime
        }
        /*
         Player blocked in front and from sides - check
         */
        print(cars.filter({ $0.hasPriority }).count)
        cars.forEach { (car: MVACar) in
            car.timeCountdown(deltaT: dTime)
            //car in-front (blocked front of car)
            checkFront(ofCar: car)
            //CHANGE LANE WHEN PRIORITY
            if car.hasPriority {
                let movePositions = car.freeToMove()
                print("hasPriority", movePositions)
                //Randomise!!!
                if movePositions.contains(.left) {
                    if car.changeLane(inDirection: .left) {
                        car.hasPriority = false
                        car.changeSpeed(CGFloat(arc4random_uniform(40)+50), durationOfChange: 1.0)
                        car.stampIt(withLabel: "done")
                    }
                } else if movePositions.contains(.right) {
                    if car.changeLane(inDirection: .right) {
                        car.hasPriority = false
                        car.changeSpeed(CGFloat(arc4random_uniform(40)+50), durationOfChange: 1.0)
                        car.stampIt(withLabel: "done")
                    }
                }
            } else if car.hasPriority == false && car.pointsPerSecond == 200 {
                car.changeSpeed(CGFloat(arc4random_uniform(40)+50), durationOfChange: 1.0)
                car.stampIt(withLabel: "done")
            }
        }
    }
    
    private func playerCornered() -> [MVACar]? {
        let badCars = player.responseFromSensors(inPositions: [.backLeft,.left,.frontLeft,.backRight,.right,.frontRight])
        let frontCars = player.responseFromSensors(inPositions: [.front])
        if frontCars.isFull && badCars.count >= 1 { //???
            return Array(badCars.union(frontCars))
        } else {
            return nil
        }
    }
    
    private func checkJam() {
        let pLane = player.currentLane
        if pLane == 0 || pLane == 2 {
            if let badCars = playerCornered() {
                print("cornered")
                freeTheWay(blockedByCars: badCars)
            }
            //special free the way for center
        }
        
        //if let carInWay = carsInFront.sorted(by: { $0.position.y < $1.position.y }).first {
        if let carInWay = cars.filter({ $0.currentLane == pLane && player.position.y < $0.position.y && $0.mindSet != .player && $0.cantMoveForTime <= 0 }).sorted(by: { $0.position.y < $1.position.y })[safe: 0] {
            let rightSide = carInWay.responseFromSensors(inPositions: [.backRight,.right,.frontRight]).filter({ $0 != player && $0.cantMoveForTime <= 0 })
            let leftSide = carInWay.responseFromSensors(inPositions: [.backLeft,.left,.frontLeft]).filter({ $0 != player && $0.cantMoveForTime <= 0 })
            let maxLane = carInWay.roadLanePositions.count-1
            
            switch (leftSide.isEmpty,rightSide.isEmpty,carInWay.currentLane) {
            case (true,false,0):
                //left lane, blocked from right
                var mostRightCars = Set<MVACar>()
                for car in rightSide {
                    mostRightCars = mostRightCars.union(car.responseFromSensors(inPositions: [.frontRight,.right,.backRight]).filter({ $0 != player }))
                }
                if mostRightCars.isFull {
                    freeTheWay(blockedByCars: [carInWay]+rightSide+Array(mostRightCars))
                }
                
            case (false,true,maxLane):
                //right lane, blocked from left
                var mostLeftCars = Set<MVACar>()
                for car in leftSide {
                    mostLeftCars = mostLeftCars.union(car.responseFromSensors(inPositions: [.frontLeft,.left,.backLeft]).filter({ $0 != player }))
                }
                if mostLeftCars.isFull {
                    freeTheWay(blockedByCars: [carInWay]+leftSide+Array(mostLeftCars))
                }
                
            case (false,false,_):
                //center lane, blocked from sides
                freeTheWay(blockedByCars: rightSide+leftSide+[carInWay])
            default: break
            }
        }
    }
    
    private func freeTheWay(blockedByCars cars: [MVACar]) {
        var carsFreeToMove = [MVACar]()
        switch arc4random_uniform(3) {
        case 0: carsFreeToMove = cars.filter({ $0.mindSet != .player })
        case 1: carsFreeToMove = cars.filter({ $0.mindSet != .player })
        case 2: carsFreeToMove = cars.filter({ $0.mindSet != .player })
        default: break
        }
        let carIndex = carsFreeToMove.map({ $0.hasPriority }).index(of: true) ?? Int(arc4random_uniform(UInt32(carsFreeToMove.count)))
        if let badCar = carsFreeToMove[safe: carIndex] {
            let movePositions = Set<MVAPosition>(badCar.freeToMove())

            if movePositions.isSuperset(of: [.left,.right]) {
                if arc4random_uniform(2) == 1 {
                    if badCar.changeLane(inDirection: .left) {
                        badCar.stampIt(withLabel: "Left")
                        badCar.hasPriority = false
                    }
                } else {
                    if badCar.changeLane(inDirection: .right) {
                        badCar.stampIt(withLabel: "Right")
                        badCar.hasPriority = false
                    }
                }
                
            } else if movePositions.contains(.left) {
                if badCar.changeLane(inDirection: .left) {
                    badCar.stampIt(withLabel: "Left")
                    badCar.hasPriority = false
                }
            } else if movePositions.contains(.right) {
                if badCar.changeLane(inDirection: .right) {
                    badCar.stampIt(withLabel: "Right")
                    badCar.hasPriority = false
                }
            } else {
                badCar.changeSpeed(200, durationOfChange: 1.0)
                badCar.stampIt(withLabel: "Speed")
                badCar.hasPriority = true
            }
            // no more 'collisions' completion -> hasPriority = false
        }
    }
}

