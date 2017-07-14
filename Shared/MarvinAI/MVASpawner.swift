//
//  MVACarSpawner.swift
//  (un)Predictable
//
//  Created by Majo on 27/12/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit

class MVASpawner: SKSpriteNode {
    // MARK: - Car Section
    class func createCarSpawner(withSize size: CGSize) -> MVASpawner {
        let spawner = MVASpawner(color: .clear, size: CGSize(width: size.width, height: size.height))
        return spawner
    }
    
    private var lastLaneSpawn: Int?
    let textures = SKTextureAtlas(named: "Cars")
    private var doubleSpawnLimit = 0
    var usedCars = [MVACar]()
    
    func spawnCar(withExistingCars cars: [MVACar], roadLanes: [Int:Int]) -> [MVACar] {
        var intersectingCars = [Int]()
        for car in cars {
            if self.intersects(car) {
                intersectingCars.append(car.currentLane)
            }
        }
        
        if intersectingCars.isEmpty && doubleSpawnLimit <= 0 && arc4random_uniform(2) == 1 {
            lastLaneSpawn = arc4random_uniform(2) == 0 ? 0:2
            var cars = [MVACar]()
            for lane in randomDoubleCombo() {
                let car = gimmeCar()
                car.currentLane = lane
                car.position = CGPoint(x: randomiseXPosition(roadLanes[lane]!), y: self.position.y)
                car.pointsPerSecond = MVAConstants.baseBotSpeed
                cars.append(car)
            }
            doubleSpawnLimit = Int(arc4random_uniform(3))+5
            return cars
        } else if intersectingCars.count < 2 {//!!! even more than 2
            doubleSpawnLimit -= 1
            let carLane = randomLaneWithLanesOccupied(intersectingCars)
            lastLaneSpawn = carLane
            
            let car = gimmeCar()
            car.currentLane = carLane
            car.position = CGPoint(x: randomiseXPosition(roadLanes[carLane]!), y: self.position.y)
            car.pointsPerSecond = MVAConstants.baseBotSpeed
            
            return [car]
        }
        return []
    }
    
    private func gimmeCar() -> MVACar {
        var car: MVACar!
        if usedCars.isEmpty {
            car = MVACar(withMindSet: .bot, andSkin: randomCarSkin())
            car.useCounter = 1
        } else {
            car = usedCars.removeFirst()
            car.useCounter += 1
            if car.useCounter > 5 {
                car.skin = randomCarSkin()
                car.texture = car.skin.normal
            }
        }
        
        return car
    }
    
    private func randomCarSkin() -> MVASkin {
        switch arc4random_uniform(4) {
        case 0: return MVASkin.createForCar("car", withAtlas: self.textures)
        case 1: return MVASkin.createForCar("taxi", withAtlas: self.textures)
        case 2: return MVASkin.createForCar("mini_van", withAtlas: self.textures)
        default: return MVASkin.createForCar("prius", withAtlas: self.textures)
        }
    }
    
    private var playerLane: Int? {
        return (self.parent as! GameScene).intel.player?.currentLane
    }
    
    private func randomLaneWithLanesOccupied(_ lns: [Int]) -> Int {
        var newLane: Int?
        
        if lastLaneSpawn == playerLane {
            let oldLane = lns.first != nil ? lns.first!:(lastLaneSpawn ?? Int(arc4random_uniform(3)))
            
            if oldLane == 2 {
                randomise(f1: { newLane = oldLane-1 }, f2: { newLane = oldLane-2 })
            } else if oldLane == 0 {
                randomise(f1: { newLane = oldLane+1 }, f2: { newLane = oldLane+2 })
            } else {
                randomise(f1: { newLane = oldLane+1 }, f2: { newLane = oldLane-1 })
            }
        } else {
            newLane = playerLane
        }
        
        return newLane ?? Int(arc4random_uniform(3))
    }
    
    private func randomDoubleCombo() -> [Int] {
        switch arc4random_uniform(3) {
        case 0: return [0,1]
        case 1: return [1,2]
        default: return [0,2]
        }
    }
    
    private func randomise(f1: ()->(), f2: ()->()) {
        if arc4random_uniform(2) == 0 { f1() } else { f2() }
    }
    
    private func randomiseXPosition(_ posX: Int) -> CGFloat {
        let wiggleRoom = Int(arc4random_uniform(9)+1)
        if arc4random_uniform(2) == 1 {
            return CGFloat(posX+wiggleRoom)
        } else {
            return CGFloat(posX-wiggleRoom)
        }
    }
    
    // MARK: - Road Section
    var usedRoad = [MVARoadNode]()
    var roadTexture = SKTexture(imageNamed: "Road")
    
    func spawnRoad(withSize rSize: CGSize) -> MVARoadNode? {
        var road: MVARoadNode!
        if usedRoad.isEmpty {
            road = MVARoadNode.createWith(numberOfLanes: 3, texture: roadTexture, height: rSize.height, andWidth: rSize.width)
        } else {
            road = usedRoad.removeFirst()
        }
        
        return road
    }
    
}
