//
//  MVAMarvinRuleConstantSpeed.swift
//  (un)Predictable
//
//  Created by Majo on 22/12/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import CoreGraphics

struct MVAArea {/// MVA??? convention?
    let xRange: ClosedRange<CGFloat>
    let yRange: ClosedRange<CGFloat>
    
    func contains(point: CGPoint) -> Bool {
        return xRange.contains(point.x) && yRange.contains(point.y)
    }
    //add func intersects
}

class MVAMarvinRuleConstantSpeed {
    
    class func move(entity: MVAMarvinEntity, withDeltaTime dTime: Double, avoid: Set<MVAMarvinEntity>) {
        let velocity = CGPoint(x: 0.0, y: entity.pointsPerSecond)
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dTime), y: velocity.y * CGFloat(dTime))
        let newPosition = CGPoint(x: entity.position.x + amountToMove.x, y: entity.position.y + amountToMove.y)
        let avoidEntities = avoid.map { (entity: MVAMarvinEntity) -> MVAArea in
            let topX = entity.position.x+entity.size.width/2
            let bottomX = entity.position.x-entity.size.width/2
            let topY = entity.position.y+entity.size.height/2
            let bottomY = entity.position.y-entity.size.height/2
            return MVAArea(xRange: bottomX...topX, yRange: bottomY...topY)
        }
        let controlPoint = CGPoint(x: entity.position.x, y: entity.position.y+entity.size.height)
        if avoidEntities.map({ $0.contains(point: controlPoint) }).contains(true) == false {
            entity.position = newPosition
        } else {
            /*//If there's car in front
            if (entity as? MVACar)?.isMoving == false {
                let leftLaneTOPX = CGPoint(x: entity.position.x-entity.size.width, y: entity.position.y+entity.size.height/2)
                let leftLaneBOTTX = CGPoint(x: entity.position.x-entity.size.width, y: entity.position.y-entity.size.height/2)
                let rightLaneTOPX = CGPoint(x: entity.position.x+entity.size.width, y: entity.position.y+entity.size.height/2)
                let rightLaneBOTTX = CGPoint(x: entity.position.x+entity.size.width, y: entity.position.y-entity.size.height/2)
                if avoidEntities.map({ $0.contains(point: leftLaneTOPX) || $0.contains(point: leftLaneBOTTX) }).contains(true) == false && (entity as? MVACar)?.currentLane != 1 {
                    (entity as? MVACar)?.change(lane: -1)
                } else if avoidEntities.map({ $0.contains(point: rightLaneTOPX) || $0.contains(point: rightLaneBOTTX) }).contains(true) == false && (entity as? MVACar)?.currentLane != 3 {
                    (entity as? MVACar)?.change(lane: 1)
                }
            }*/
        }
    }
    
    class func move(entity: MVAMarvinEntity, withDeltaTime dTime: Double) {
        let velocity = CGPoint(x: 0.0, y: entity.pointsPerSecond)
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dTime), y: velocity.y * CGFloat(dTime))
        let newPosition = CGPoint(x: entity.position.x + amountToMove.x, y: entity.position.y + amountToMove.y)
        entity.position = newPosition
    }
}
