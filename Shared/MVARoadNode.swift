//
//  RoadGenerator.swift
//  (un)Predictable
//
//  Created by Majo on 21/10/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit

class MVARoadNode: SKSpriteNode {
    var numberOfLanes: UInt32 = 0
    
    class func createWith(numberOfLanes: Int, height: CGFloat, andWidth width: CGFloat) -> MVARoadNode {
        let road = MVARoadNode()
        road.numberOfLanes = UInt32(numberOfLanes)
        
        let createLanes = numberOfLanes
        
        //leftGrass
        let lGrass = SKSpriteNode(imageNamed: "LeftGrass")
        lGrass.anchorPoint = CGPoint.zero
        lGrass.position = CGPoint.zero
        road.addChild(lGrass)
        //firstLane
        let fLane = SKSpriteNode(imageNamed: "LeftLane")
        fLane.anchorPoint = CGPoint.zero
        fLane.position = CGPoint(x: lGrass.size.width, y: 0.0)
        road.addChild(fLane)
        var xEndOflastLane = fLane.position.x+fLane.size.width
        
        for _ in 2..<createLanes {
            let lane = SKSpriteNode(imageNamed: "MiddleLane")
            lane.anchorPoint = CGPoint.zero
            lane.position = CGPoint(x: xEndOflastLane, y: 0.0)
            xEndOflastLane += lane.size.width
            road.addChild(lane)
        }
        //lastLane
        let lLane = SKSpriteNode(imageNamed: "RightLane")
        lLane.anchorPoint = CGPoint.zero
        lLane.position = CGPoint(x: xEndOflastLane, y: 0.0)
        xEndOflastLane += lLane.size.width
        road.addChild(lLane)
        //rightGrass
        let rGrass = SKSpriteNode(imageNamed: "RightGrass")
        rGrass.anchorPoint = CGPoint.zero
        rGrass.position = CGPoint(x: xEndOflastLane, y: 0.0)
        xEndOflastLane += rGrass.size.width
        road.addChild(rGrass)
        
        road.size = CGSize(width: width, height: height)
        road.name = "road"
        road.anchorPoint = CGPoint.zero
        
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
        road.zPosition = -0.1
        return road
    }
}
