//
//  MVAStopperNode.swift
//  unPredictable
//
//  Created by Majo on 28/04/2018.
//  Copyright © 2018 MarVin. All rights reserved.
//

import SpriteKit

class MVAStopperNode: SKSpriteNode {
    class func createStopper(withRect rect: CGRect) -> MVAStopperNode {
        let stopper = MVAStopperNode(color: .clear, size: rect.size)
        
        var physicsRect = rect
        physicsRect.origin.x = -physicsRect.size.width/2
        physicsRect.origin.y = -physicsRect.size.height/2
        stopper.physicsBody = SKPhysicsBody(edgeLoopFrom: physicsRect)
        stopper.physicsBody?.affectedByGravity = false
        stopper.physicsBody?.isDynamic = false
        stopper.physicsBody?.restitution = 0.0
        //remover.physicsBody?.categoryBitMask = MVAPhysicsCategory.remover.rawValue
        //remover.physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue
        
        return stopper
    }
}
