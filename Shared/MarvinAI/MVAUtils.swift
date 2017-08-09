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

enum MVAMindSet {
    case player
    case bot
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

extension CGSize {
    func adjustSize(toNewWidth newWidth: CGFloat) -> CGSize {
        let aspectRatio = self.width/self.height
        return CGSize(width: newWidth, height: newWidth/aspectRatio)
    }
}
