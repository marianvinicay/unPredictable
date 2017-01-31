//
//  MVAGameLogic.swift
//  (un)Predictable
//
//  Created by Majo on 30/10/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit

extension Double {
    static func randomWith2Decimals(inRange range: Range<UInt32>) -> Double {
        let decNumb = Double(arc4random_uniform(98)+1)/100
        let numb = arc4random_uniform(range.upperBound)+range.lowerBound
        return Double(numb)+decNumb
    }
}

class MVAGameLogic {
    var currentLane: Int!
}
