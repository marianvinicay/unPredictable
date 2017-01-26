//
//  PlayerCar.swift
//  (un)Predictable
//
//  Created by Majo on 30/10/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit

class MVACar: MVAMarvinEntity {
    
    private var roadLanes: [Int:CGFloat] {
        get {
            return (self.parent as? GameScene)?.lanes ?? [:]
        }
    }
    
    var isMoving = false
    
    var currentLane: Int!
    
    class func create(withMindSet mSet: MVAMindSet) -> MVACar {
        let car = MVACar(withSize: CGSize(width: 69.0, height: 150.0), andMindSet: .player, color: UIColor.red)
                
        car.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 69.0, height: 150.0))
        car.physicsBody?.collisionBitMask = 0
        car.physicsBody?.categoryBitMask = MVAPhysicsCategory.car.rawValue
        car.physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue
        car.physicsBody?.isDynamic = true
        car.physicsBody?.affectedByGravity = false
        car.physicsBody?.allowsRotation = false
        
        return car
    }
    
    func change(lane: Int) {
        let newLane = currentLane+lane
        if self.roadLanes.keys.contains(newLane) {
            if let newLaneCoor = roadLanes[newLane] {
                self.isMoving = true
                currentLane = newLane
                let endMoving = SKAction.run({
                    self.isMoving = false
                })
                let move = SKAction.moveTo(x: newLaneCoor, duration: 1.0)
                self.run(SKAction.sequence([move,endMoving]))
            }
        }
    }
}
