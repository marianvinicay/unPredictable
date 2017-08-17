//
//  MVARemoverNode.swift
//  unPredictable
//
//  Created by Majo on 17/08/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

class MVARemoverNode: SKSpriteNode {
    class func createRemover(withSize size: CGSize) -> MVARemoverNode {
        let remover = MVARemoverNode(color: .clear, size: CGSize(width: size.width, height: size.height))
        
        remover.physicsBody = SKPhysicsBody(rectangleOf: remover.size)
        remover.physicsBody?.affectedByGravity = false
        remover.physicsBody?.isDynamic = false
        remover.physicsBody?.categoryBitMask = MVAPhysicsCategory.remover.rawValue
        remover.physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue
        
        return remover
    }
}
