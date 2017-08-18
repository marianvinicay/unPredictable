//
//  MVACarSpawner.swift
//  (un)Predictable
//
//  Created by Majo on 27/12/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit

class MVASpawnerNode: SKSpriteNode {
    // MARK: - Car Section
    class func createCarSpawner(withSize size: CGSize) -> MVASpawnerNode {
        let spawner = MVASpawnerNode(color: .clear, size: CGSize(width: size.width, height: size.height))
        return spawner
    }
    
    private var lastLaneSpawn: Int?
    private var doubleSpawnLimit = 0
    let textures = SKTextureAtlas(named: "Cars")
    let roadTexture = SKTexture(imageNamed: "road")
    var usedCars = Set<MVACarBot>()
    
    private var playerLane: Int? {
        return (self.parent as! GameScene).intel.player?.currentLane
    }
        
    func spawnCar(withExistingCars cars: [MVACarBot]) {
        var intersectingCars = [Int]()
        for car in cars {
            if self.intersects(car) {
                intersectingCars.append(car.currentLane)
            }
        }
        
        if intersectingCars.isEmpty && doubleSpawnLimit <= 0 && arc4random_uniform(2) == 1 {
            lastLaneSpawn = arc4random_uniform(2) == 0 ? 0:maxLane
            var cars = [MVACarBot]()
            for lane in randomDoubleCombo() {
                let car = gimmeCar()
                car.currentLane = lane
                car.position = CGPoint(x: randomiseXPosition(lanePositions[lane]!), y: self.position.y)
                car.pointsPerSecond = MVAConstants.baseBotSpeed
                cars.append(car)
            }
            doubleSpawnLimit = Int(arc4random_uniform(3))+4
            for car in cars {
                (self.parent as! GameScene).addChild(car)
                (self.parent as! GameScene).intel.cars.insert(car)
            }
        } else if intersectingCars.count < maxLane {
            doubleSpawnLimit -= 1
            let carLane = randomLaneWithLanesOccupied(intersectingCars)
            lastLaneSpawn = carLane
            
            let car = gimmeCar()
            car.currentLane = carLane
            car.position = CGPoint(x: randomiseXPosition(lanePositions[carLane]!), y: self.position.y)
            car.pointsPerSecond = MVAConstants.baseBotSpeed
            
            (self.parent as! GameScene).addChild(car)
            (self.parent as! GameScene).intel.cars.insert(car)
        }
    }
    
    private func gimmeCar() -> MVACarBot {
        var car: MVACarBot!
        if usedCars.isEmpty {
            car = MVACarBot.new(withSkin: randomCarSkin())
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
        switch arc4random_uniform(7) {
        case 0: return MVASkin.createForCar(MVACarNames.muscle, withAtlas: self.textures)
        case 1: return MVASkin.createForCar(MVACarNames.taxi, withAtlas: self.textures)
        case 2: return MVASkin.createForCar(MVACarNames.offRoad, withAtlas: self.textures)
        case 3: return MVASkin.createForCar(MVACarNames.electric, withAtlas: self.textures)
        case 4: return MVASkin.createForCar(MVACarNames.van, withAtlas: self.textures)
        case 5: return MVASkin.createForCar(MVACarNames.hybrid, withAtlas: self.textures)
        default: return MVASkin.createForCar(MVACarNames.classic, withAtlas: self.textures)
        }
    }
    
    private func randomLaneWithLanesOccupied(_ lns: [Int]) -> Int {
        var newLane: Int?
        
        if lastLaneSpawn == playerLane {
            let oldLane = lns.first != nil ? lns.first!:(lastLaneSpawn ?? Int(arc4random_uniform(UInt32(maxLane+1))))
            
            switch oldLane {
            case maxLane:
                var possibleFS = [()->()]()
                for l in 1...maxLane {
                    possibleFS.append {
                        newLane = oldLane-l
                    }
                }
                randomise(possibleFS)
            case 0:
                var possibleFS = [()->()]()
                for l in 1...maxLane {
                    possibleFS.append {
                        newLane = oldLane+l
                    }
                }
                randomise(possibleFS)
            default:
                var possibleFS = [()->()]()
                for minusL in 1...oldLane {
                    possibleFS.append {
                        newLane = oldLane-minusL
                    }
                }
                for plusL in 1...(maxLane-oldLane) {
                    possibleFS.append {
                        newLane = oldLane+plusL
                    }
                }
                randomise(possibleFS)
            }
        } else {
            newLane = playerLane
        }
        
        return newLane ?? Int(arc4random_uniform(3))
    }
    
    private func randomDoubleCombo() -> [Int] {
        #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .phone {
                switch arc4random_uniform(3) {
                case 0: return [0,1]
                case 1: return [1,2]
                default: return [0,2]
                }
            } else {
                switch arc4random_uniform(6) {
                case 0: return [0,1]
                case 1: return [0,2]
                case 2: return [1,2]
                case 3: return [1,3]
                case 4: return [2,3]
                default: return [0,3]
                }
            }
        #elseif os(watchOS)
            return [Int(arc4random_uniform(2))]
        #endif
    }
    
    private func randomise(_ fs: [()->()]) {
        let randIndex = Int(arc4random_uniform(UInt32(fs.count)))
        fs[randIndex]()
    }
    
    private func randomiseXPosition(_ posX: Int) -> CGFloat {
        let wiggleRoom = Int(arc4random_uniform(9)+1)
        if arc4random_uniform(2) == 1 {
            return CGFloat(posX+wiggleRoom)
        } else {
            return CGFloat(posX-wiggleRoom)
        }
    }
}
