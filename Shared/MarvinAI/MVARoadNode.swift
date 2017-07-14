//
//  RoadGenerator.swift
//  (un)Predictable
//
//  Created by Majo on 21/10/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit

class MVARoadNode: SKSpriteNode {
    var laneXCoordinate: [Int:Int] = [:]
    
    class func createWith(numberOfLanes: Int, texture: SKTexture, height: CGFloat, andWidth width: CGFloat) -> MVARoadNode {
        let road = MVARoadNode(texture: texture)
        let createLanes = numberOfLanes-1
        let sidesWidthCombined = width*(1/3)
        let laneWidth = (width-sidesWidthCombined)/CGFloat(numberOfLanes)
        
        var tempCoordinates = -(width/2)
        //leftGrass
        tempCoordinates = (tempCoordinates+sidesWidthCombined/2).roundTo(NDecimals: 2)
        //firstLane
        road.laneXCoordinate[0] = Int(tempCoordinates+laneWidth/2)
        tempCoordinates += laneWidth
        
        for i in 1..<createLanes {
            road.laneXCoordinate[i] = Int(tempCoordinates+laneWidth/2)
            tempCoordinates += laneWidth
        }
        
        //lastLane
        road.laneXCoordinate[createLanes] = Int(tempCoordinates+laneWidth/2)
        
        road.size = CGSize(width: width, height: height)

        road.zPosition = 0.0
        return road
    }
}
