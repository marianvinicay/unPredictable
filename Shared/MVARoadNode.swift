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
    
    class func createWith(numberOfLanes: Int, height: CGFloat, andWidth width: CGFloat) -> MVARoadNode {
        let road = MVARoadNode(imageNamed: "road")
        road.numberOfLanes = UInt32(numberOfLanes)
        
        let createLanes = numberOfLanes-1
        let laneWidth = width/CGFloat(numberOfLanes+2)
        
        var tempCoordinates = CGFloat(0.0)
        //leftGrass
        tempCoordinates = laneWidth
        //firstLane
        road.laneXCoordinate[0] = tempCoordinates+laneWidth/2
        tempCoordinates += laneWidth
        
        for i in 1..<createLanes {
            road.laneXCoordinate[i] = tempCoordinates+laneWidth/2
            tempCoordinates += laneWidth
        }
        
        //lastLane
        road.laneXCoordinate[createLanes] = tempCoordinates+laneWidth/2
        tempCoordinates += laneWidth
        //rightGrass
        //???
        
        road.size = CGSize(width: width, height: height)
        road.name = "road"
        road.anchorPoint = .zero
        //road.position.y -= road.size.height/2
        
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
    
    /*///Minimal numberOfLanes is 2
    class func createWith(numberOfLanes: Int, height: CGFloat, andWidth width: CGFloat) -> MVARoadNode {
        let road = MVARoadNode()
        road.numberOfLanes = UInt32(numberOfLanes)
        
        let createLanes = numberOfLanes-1
        let laneWidth = width/CGFloat(numberOfLanes+2)
        
        //leftGrass
        let lGrass = SKSpriteNode(imageNamed: "LeftGrass")
        lGrass.size.width = laneWidth
        lGrass.position.x = lGrass.size.width/2
        road.addChild(lGrass)
        //firstLane
        let fLane = SKSpriteNode(imageNamed: "LeftLane")
        fLane.size.width = laneWidth
        fLane.position.x = (lGrass.size.width+fLane.size.width/2)-1
        fLane.zPosition = 0.0
        road.laneXCoordinate[0] = fLane.position.x//+(fLane.size.width/2)
        road.addChild(fLane)
        var xEndOflastLane = fLane.position.x+fLane.size.width/2
        
        for i in 1..<createLanes {
            let lane = SKSpriteNode(imageNamed: "MiddleLane")
            lane.size.width = laneWidth
            lane.zPosition = 0.2
            lane.position.x = (xEndOflastLane+lane.size.width/2)-1
            road.laneXCoordinate[i] = lane.position.x//+(lane.size.width/2)
            xEndOflastLane += lane.size.width-1
            road.addChild(lane)
        }
        
        //lastLane
        let lLane = SKSpriteNode(imageNamed: "RightLane")
        lLane.size.width = laneWidth
        lLane.zPosition = 0.0
        lLane.position.x = (xEndOflastLane+lLane.size.width/2)-1
        road.laneXCoordinate[createLanes] = lLane.position.x//+(lLane.size.width/2)
        xEndOflastLane += lLane.size.width-1
        road.addChild(lLane)
        //rightGrass
        let rGrass = SKSpriteNode(imageNamed: "RightGrass")
        rGrass.size.width = laneWidth
        rGrass.position.x = xEndOflastLane+rGrass.size.width/2
        xEndOflastLane += rGrass.size.width
        road.addChild(rGrass)
        
        road.size = CGSize(width: width, height: height)
        road.name = "road"
        //road.position.y -= road.size.height/2
        
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
    }*/
}
