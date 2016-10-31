//
//  RoadGenerator.swift
//  (un)Predictable
//
//  Created by Majo on 21/10/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit

class MVARoadGenerator {
    class func tiles(withHeight height: CGFloat) -> SKSpriteNode {
        let texture = SKTexture(image: #imageLiteral(resourceName: "road"))
        let firstTile = SKSpriteNode(texture: texture)
        firstTile.anchorPoint = CGPoint.zero
        firstTile.zPosition = -0.1
        let tiles = SKSpriteNode()
        tiles.anchorPoint = CGPoint.zero
        tiles.addChild(firstTile)
        tiles.name = "road"
        /*if height > firstTile.size.height {
            var lastY = firstTile.size.height
            do {
                let tile = SKSpriteNode(imageNamed: "road")
                tile.anchorPoint = CGPoint.zero
                tile.position = CGPoint(x: lastY, y: 0)
                lastY = tile.size.height
                tiles.addChild(tile)
            } while
        }*/
        tiles.zPosition = -0.1
        firstTile.name = "road"
        return firstTile
    }
}
