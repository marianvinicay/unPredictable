//
//  HUD.swift
//  (un)Predictable
//
//  Created by Majo on 28/06/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

class HUD: SKNode {
    private let distanceLabel: SKLabelNode
    private let levelLabel: SKLabelNode
    
    init(distL: SKLabelNode, lvlL: SKLabelNode) {
        distanceLabel = distL
        levelLabel = lvlL
        super.init()
        self.addChild(distanceLabel)
        self.addChild(levelLabel)
    }
    
    func setDistance(_ dist: Double) {
        var distString = String(dist)
        let decIndex = distString.range(of: ".")!.lowerBound
        let ind = distString.index(decIndex, offsetBy: 2)
        distString = distString.substring(to: ind)
        distanceLabel.text = distString + " KM"
    }
    
    func setLevel(_ lvl: Int) {
        levelLabel.text = String(lvl)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
