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
    private var starterCount = 0
    
    class func createWith(numberOfLanes: Int, name: String, height: CGFloat, andWidth width: CGFloat) -> MVARoadNode {
        let road = MVARoadNode(imageNamed: name)
        road.numberOfLanes = UInt32(numberOfLanes)
        
        let createLanes = numberOfLanes-1
        let sidesWidthCombined = width*(1/3)
        let laneWidth = (width-sidesWidthCombined)/CGFloat(numberOfLanes)
        
        var tempCoordinates = -(width/2)
        //leftGrass
        tempCoordinates = (tempCoordinates+sidesWidthCombined/2).roundTo(NDecimals: 2)
        //firstLane
        road.laneXCoordinate[0] = (tempCoordinates+laneWidth/2).roundTo(NDecimals: 2)
        tempCoordinates += laneWidth
        
        for i in 1..<createLanes {
            road.laneXCoordinate[i] = (tempCoordinates+laneWidth/2).roundTo(NDecimals: 2)
            tempCoordinates += laneWidth
        }
        
        //lastLane
        road.laneXCoordinate[createLanes] = (tempCoordinates+laneWidth/2).roundTo(NDecimals: 2)
        
        road.size = CGSize(width: width, height: height)

        road.zPosition = -0.1
        return road
    }
}
