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
    
    class func createWith(texture: SKTexture, height: CGFloat, andWidth width: CGFloat) -> MVARoadNode {
        let road = MVARoadNode(texture: texture)
        road.size = CGSize(width: width, height: height)
        
        if lanePositions.isEmpty {
            var numberOfLanes = 3
            if UIDevice.current.userInterfaceIdiom == .pad {
                numberOfLanes = 4
            }
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
            lanePositions[0] = Int(tempCoordinates+laneWidth/2)
            tempCoordinates += laneWidth
            
            for i in 1..<createLanes {
                lanePositions[i] = Int(tempCoordinates+laneWidth/2)
                tempCoordinates += laneWidth
            }
            
            //lastLane
            lanePositions[createLanes] = Int(tempCoordinates+laneWidth/2)
        }
        
        road.zPosition = 0.0
        return road
    }
}
