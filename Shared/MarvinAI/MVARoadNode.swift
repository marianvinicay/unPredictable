//
//  RoadGenerator.swift
//  (un)Predictable
//
//  Created by Majo on 21/10/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit
#if os(iOS)
import UIKit
#endif

class MVARoadNode: SKSpriteNode {
    var laneCoordinates: [Int:Int] = [:]
    
    class func createWith(texture: SKTexture, height: CGFloat, andWidth width: CGFloat) -> MVARoadNode {
        var numberOfLanes = 3
        if UIDevice.current.userInterfaceIdiom == .pad {
            numberOfLanes = 4
        }
        let road = MVARoadNode(texture: texture)
        let createLanes = numberOfLanes-1
        var sidesWidthCombined = (width*(1/3))-20
        #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                sidesWidthCombined = width*(1/4)-20
            }
        #endif
        let laneWidth = (width-sidesWidthCombined)/CGFloat(numberOfLanes)
        
        var tempCoordinates = -(width/2)
        //leftGrass
        tempCoordinates = (tempCoordinates+sidesWidthCombined/2).roundTo(NDecimals: 2)
        //firstLane
        road.laneCoordinates[0] = Int(tempCoordinates+laneWidth/2)
        tempCoordinates += laneWidth
        
        for i in 1..<createLanes {
            road.laneCoordinates[i] = Int(tempCoordinates+laneWidth/2)
            tempCoordinates += laneWidth
        }
        
        //lastLane
        road.laneCoordinates[createLanes] = Int(tempCoordinates+laneWidth/2)
        
        road.size = CGSize(width: width, height: height)

        road.zPosition = 0.0
        return road
    }
}
