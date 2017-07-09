//
//  MVACarSpawner.swift
//  (un)Predictable
//
//  Created by Majo on 27/12/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit

class MVACarSpawner: SKSpriteNode {
    class func createSpawner(withWidth width: CGFloat) -> MVACarSpawner {
        let spawner = MVACarSpawner(color: .red, size: CGSize(width: width, height: 200.0))
        spawner.physicsBody = SKPhysicsBody(rectangleOf: spawner.size)
        spawner.physicsBody?.affectedByGravity = false
        spawner.physicsBody?.isDynamic = false
        spawner.physicsBody?.categoryBitMask = MVAPhysicsCategory.spawner.rawValue
        spawner.physicsBody?.collisionBitMask = MVAPhysicsCategory.spawner.rawValue
        //spawner.physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue
        
        return spawner
    }
    
    private var lastLaneSpawn: Int?
    
    func spawn(withExistingCars cars: Set<MVACar>, roadLanes: [Int:CGFloat]) {
        var intersectingCars = Set<MVACar>()
        for car in cars {
            if self.intersects(car) {
                intersectingCars.insert(car)
            }
        }
        if intersectingCars.count < 2 {//!!! even more than 2
            var carLane = Int(arc4random_uniform(3))//!!!
            //repeat...while
            while intersectingCars.map({ $0.currentLane }).contains(where: { $0 == carLane }) || carLane == lastLaneSpawn {
                carLane = Int(arc4random_uniform(3))
            }
            lastLaneSpawn = carLane
            let position = CGPoint(x: randomiseXPosition(roadLanes[carLane]!), y: self.position.y)
            var img = "Car"
            let rand = arc4random_uniform(3)
            if rand == 1 {
                img = "Mini_van"
            } else if rand == 2 {
                img = "taxi"
            }
            let car = MVACar(withMindSet: .bot, andSkin: img)
            car.currentLane = carLane
            car.position = position
            
            car.zPosition = 4.0
            car.pointsPerSecond = MVAConstants.baseBotSpeed
            (self.parent as! GameScene).addChild(car)
            (self.parent as! GameScene).intel.cars.insert(car)
        }
    }
    
    func randomiseXPosition(_ posX: CGFloat) -> CGFloat {
        let wiggleRoom = CGFloat(arc4random_uniform(9)+1)
        if arc4random_uniform(2) == 1 {
            return posX+wiggleRoom
        } else {
            return posX-wiggleRoom
        }
    }
    
}
