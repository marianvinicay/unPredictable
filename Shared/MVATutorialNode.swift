//
//  MVATutorialNode.swift
//  unPredictable
//
//  Created by Majo on 26/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

class MVATutorialNode: SKNode {
    class func new(size: CGSize) -> MVATutorialNode {
        let newNode = MVATutorialNode()
        
        let swipeLabel = SKLabelNode(text: "Swipe to change your car's lane")
        swipeLabel.fontName = "Futura Medium"
        swipeLabel.fontColor = .black
        swipeLabel.fontSize = 30
        swipeLabel.verticalAlignmentMode = .center
        swipeLabel.position = .zero
        /*let blank =  SKSpriteNode(color: .clear, size: size)
        blank.position = .zero
        newNode.addChild(blank)
        newNode.isUserInteractionEnabled = true*/
        return newNode
    }
}
