//
//  MVAMarvinEntity.swift
//  (un)Predictable
//
//  Created by Majo on 19/11/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import Foundation
import CoreGraphics
import SpriteKit


class MVAMarvinEntity: SKSpriteNode {
    var mindSet: MVAMindSet
    var pointsPerSecond = 0.0
    var rules = [MVAMarvinRule]()
    var ruleWeights = [Int]()
    
    init(withSize size: CGSize, andMindSet mindSet: MVAMindSet, color: UIColor) {
        self.mindSet = mindSet
        super.init(texture: nil, color: color, size: size)
        self.position = CGPoint.zero
    }
    
    required init?(coder aDecoder: NSCoder) {//???
        //return SKSpriteNode(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
}
