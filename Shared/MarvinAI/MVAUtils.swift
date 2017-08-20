//
//  MVAMindSet.swift
//  (un)Predictable
//
//  Created by Majo on 19/11/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import Foundation
import SpriteKit

struct MVASkin {
    let name: String
    
    let normal: SKTexture
    let left: SKTexture
    let right: SKTexture
    let brake: SKTexture
    
    static func createForCar(_ name: String, withAtlas atlas: SKTextureAtlas) -> MVASkin {
        let textureNames = [
            name+"Left",
            name+"Right",
            name+"Brake",
            ]
        return MVASkin(name: name, normal: atlas.textureNamed(name), left: atlas.textureNamed(textureNames[0]), right: atlas.textureNamed(textureNames[1]), brake: atlas.textureNamed(textureNames[2]))
    }
}

enum MVAPosition/*: CustomStringConvertible*/ {
    /*
     car = ⍓
     
     FL | F | FR
     –––––––––--
     L  | ⍓ |  R
     -----------
     BL | B | BR
     */
    case frontLeft, front, frontRight
    case right, left
    case back, backLeft, backRight
    case stop
    
    //DEBUG
    /*var description: String {
        switch self {
        case .front: return "front"
        case .frontLeft: return "frontLeft"
        case .frontRight: return "frontRight"
        case .right: return "right"
        case .left: return "left"
        case .back: return "back"
        case .backLeft: return "backLeft"
        case .backRight: return "backRight"
        }
    }*/
}

enum MVAPhysicsCategory: UInt32 {
    case car = 0b1
    case player = 0b10
    case remover = 0b100
    case spawner = 0b1000
}

enum MVAColor {
    #if os(macOS)
        static let normBeige = NSColor(red:0.84, green:0.71, blue:0.56, alpha:1.00)
        static let mvRed = NSColor(red:0.85, green:0.10, blue:0.25, alpha:1.00)
        static let jGreen = NSColor(red:0.22, green:0.50, blue:0.10, alpha:1.00)
    #else
        static let normBeige = UIColor(red:0.84, green:0.71, blue:0.56, alpha:1.00)//UIColor(red:0.80, green:0.71, blue:0.62, alpha:1.00)
        static let mvRed = UIColor(red:0.85, green:0.10, blue:0.25, alpha:1.00)
        static let jGreen = UIColor(red:0.22, green:0.50, blue:0.10, alpha:1.00)
    #endif
}

extension CGSize {
    func adjustSize(toNewWidth newWidth: CGFloat) -> CGSize {
        let aspectRatio = self.width/self.height
        return CGSize(width: newWidth, height: newWidth/aspectRatio)
    }
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
