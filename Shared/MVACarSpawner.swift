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
        let spawner = MVACarSpawner(color: .red, size: CGSize(width: width, height: 150.0))
        spawner.physicsBody = SKPhysicsBody(rectangleOf: spawner.size)
        spawner.physicsBody?.affectedByGravity = false
        spawner.physicsBody?.isDynamic = false
        spawner.physicsBody?.categoryBitMask = MVAPhysicsCategory.car.rawValue
        spawner.physicsBody?.collisionBitMask = 0
        spawner.physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue
        
        return spawner
    }
    
    private var lastLaneSpawn: Int?
    
    func spawn(withExistingCars cars: [MVACar], roadLanes: [Int:CGFloat]) {
        var intersectingCars = [MVACar]()
        for car in cars {
            if self.intersects(car) {
                intersectingCars.append(car)
            }
        }
        if intersectingCars.count < 2 {
            var carLane = Int(arc4random_uniform(3))+1//!!!
            while intersectingCars.map({ $0.currentLane }).contains(where: { $0 == carLane }) || carLane == lastLaneSpawn {
                carLane = Int(arc4random_uniform(3))+1
            }
            lastLaneSpawn = carLane
            let position = CGPoint(x: roadLanes[carLane]!, y: self.position.y)
            let car = MVACar(withMindSet: .bot)
            car.currentLane = carLane
            car.position = position

            car.zPosition = 1.0
            car.pointsPerSecond = Double(arc4random_uniform(60)+30)
            let move = SKAction.move(by: CGVector(dx: 0.0, dy: car.pointsPerSecond), duration: 1.0)//???
            car.run(SKAction.repeatForever(move))
            car.rules.append(.randomSpeed)
            car.ruleWeights.append(1)
            car.color = (self.parent as? GameScene)?.getRandomColor() ?? UIColor.red
            (self.parent as? GameScene)?.bots.append(car)
            (self.parent as? GameScene)?.addChild(car)
            (self.parent as? GameScene)?.intel.entities.insert(car)
        } else {
            intersectingCars.removeLast()//???
        }
    }

}
