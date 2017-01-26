//
//  MVAMarvinRuleConstantSpeed.swift
//  (un)Predictable
//
//  Created by Majo on 22/12/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import CoreGraphics

class MVAMarvinRuleConstantSpeed {
    
    class func move(entity: MVAMarvinEntity, withDeltaTime dTime: Double, avoid: Set<MVAMarvinEntity>) {
        let velocity = CGPoint(x: 0.0, y: entity.pointsPerSecond)
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dTime), y: velocity.y * CGFloat(dTime))
        let newPosition = CGPoint(x: entity.position.x + amountToMove.x, y: entity.position.y + amountToMove.y)
        var avoidEntities = avoid
        avoidEntities.remove(entity)
        let controlPoint = CGPoint(x: entity.position.x, y: entity.position.y+entity.size.height)
        if avoidEntities.map({ $0.contains(controlPoint) }).contains(true) == false {
            entity.position = newPosition
        } else {
            if (entity as? MVACar)?.isMoving == false {
                let leftLaneX = CGPoint(x: entity.position.x-entity.size.width/2, y: entity.position.y)
                let rightLaneX = CGPoint(x: entity.position.x+entity.size.width/2, y: entity.position.y)
                if avoidEntities.map({ $0.contains(leftLaneX) }).contains(true) == false && (entity as? MVACar)?.currentLane != 1 {
                    (entity as? MVACar)?.change(lane: -1)
                } else if avoidEntities.map({ $0.contains(rightLaneX) }).contains(true) == false && (entity as? MVACar)?.currentLane != 3 {
                    (entity as? MVACar)?.change(lane: 1)
                }
            }
        }
    }
    
    class func move(entity: MVAMarvinEntity, withDeltaTime dTime: Double) {
        let velocity = CGPoint(x: 0.0, y: entity.pointsPerSecond)
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dTime), y: velocity.y * CGFloat(dTime))
        let newPosition = CGPoint(x: entity.position.x + amountToMove.x, y: entity.position.y + amountToMove.y)
        entity.position = newPosition
    }
}
