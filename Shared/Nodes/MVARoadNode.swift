//
//  RoadGenerator.swift
//  unPredictable
//
//  Created by Marian Vinicay on 21/10/2016.
//  Copyright © 2016 Marvin. All rights reserved.
//

import SpriteKit
#if os(iOS)
import UIKit
#endif

public var lanePositions = [Int:Int]()
public var maxLane: Int {
    return lanePositions.count-1
}

class MVARoadNode: SKSpriteNode {
    
    class func createWith(texture: SKTexture, height: CGFloat, andWidth width: CGFloat) -> MVARoadNode {
        let road = MVARoadNode(texture: texture)
        road.size = CGSize(width: width, height: height)
        
        if lanePositions.isEmpty {
            #if os(iOS)
            var numberOfLanes = 3
            var sidesWidthCombined = (width*(1/3))-40
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                numberOfLanes = 4
                sidesWidthCombined = width*(1/4)-40
            }
            #elseif os(macOS)
            let numberOfLanes = 4
            let sidesWidthCombined = width*(1/4)-40
            #endif
            let createLanes = numberOfLanes-1

            let laneWidth = (width-sidesWidthCombined)/CGFloat(numberOfLanes)
            
            var tempCoordinates = -(width/2)
            //leftGrass
            tempCoordinates = (tempCoordinates+sidesWidthCombined/2).roundTo(NDecimals: 2)
            //firstLane
            lanePositions[0] = Int(tempCoordinates+laneWidth/2)
            tempCoordinates += laneWidth
            
            if numberOfLanes > 2 {
                for i in 1..<createLanes {
                    lanePositions[i] = Int(tempCoordinates+laneWidth/2)
                    tempCoordinates += laneWidth
                }
            }
            
            //lastLane
            lanePositions[createLanes] = Int(tempCoordinates+laneWidth/2)
        }
        
        road.zPosition = 0.0
        return road
    }
}
