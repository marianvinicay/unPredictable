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
    var laneXCoordinate: [Int:CGFloat] = [:]
    
    ///Minimal numberOfLanes is 2
    class func createWith(numberOfLanes: Int, height: CGFloat, andWidth width: CGFloat) -> MVARoadNode {
        let road = MVARoadNode()
        road.numberOfLanes = UInt32(numberOfLanes)
        
        let createLanes = numberOfLanes-1
        
        //leftGrass
        let lGrass = SKSpriteNode(imageNamed: "LeftGrass")
        lGrass.anchorPoint = CGPoint.zero
        lGrass.position = CGPoint.zero
        road.addChild(lGrass)
        //firstLane
        let fLane = SKSpriteNode(imageNamed: "LeftLane")
        fLane.anchorPoint = CGPoint.zero
        fLane.position = CGPoint(x: lGrass.size.width-1, y: 0.0)
        fLane.zPosition = 0.0
        road.laneXCoordinate[0] = fLane.position.x+(fLane.size.width/2)
        road.addChild(fLane)
        var xEndOflastLane = fLane.position.x+fLane.size.width
        
        for i in 1..<createLanes {
            let lane = SKSpriteNode(imageNamed: "MiddleLane")
            lane.anchorPoint = CGPoint.zero
            lane.zPosition = 0.2
            lane.position = CGPoint(x: xEndOflastLane-1, y: 0)
            road.laneXCoordinate[i] = lane.position.x+(lane.size.width/2)
            xEndOflastLane += lane.size.width-1
            road.addChild(lane)
        }
        
        //lastLane
        let lLane = SKSpriteNode(imageNamed: "RightLane")
        lLane.anchorPoint = CGPoint.zero
        lLane.zPosition = 0.0
        lLane.position = CGPoint(x: xEndOflastLane-1, y: 0)
        road.laneXCoordinate[createLanes] = lLane.position.x+(lLane.size.width/2)
        xEndOflastLane += lLane.size.width-1
        road.addChild(lLane)
        //rightGrass
        let rGrass = SKSpriteNode(imageNamed: "RightGrass")
        rGrass.anchorPoint = CGPoint.zero
        rGrass.position = CGPoint(x: xEndOflastLane, y: 0)
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
