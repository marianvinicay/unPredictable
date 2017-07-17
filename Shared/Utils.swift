//
//  Utils.swift
//  (un)Predictable
//
//  Created by Majo on 30/10/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import Foundation
import CoreGraphics

enum MVAPhysicsCategory: UInt32 {
    case car = 0b1
    case player = 0b10
    case remover = 0b100
    case spawner = 0b1000
}

extension Collection where Indices.Iterator.Element == Index {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Double {
    static func randomWith2Decimals(inRange range: Range<UInt32>) -> Double {
        let decNumb = Double(arc4random_uniform(98)+1)/100
        let numb = arc4random_uniform(range.upperBound)+range.lowerBound
        return Double(numb)+decNumb
    }
    
    func roundTo(NDecimals dec: UInt8) -> Double {
        var divisor = 1.0
        for _ in 1...dec {
            divisor *= 10
        }
        let biggerNum = self*divisor
        return Darwin.round(biggerNum)/divisor
    }
}

extension CGFloat {
    func roundTo(NDecimals dec: UInt8) -> CGFloat {
        let roundedNum = Double(self).roundTo(NDecimals: dec)
        return CGFloat(roundedNum)
    }
}
