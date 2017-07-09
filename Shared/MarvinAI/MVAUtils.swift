//
//  MVAMindSet.swift
//  (un)Predictable
//
//  Created by Majo on 19/11/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import Foundation

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
