//
//  MVATutorialNode.swift
//  unPredictable
//
//  Created by Majo on 26/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

enum MVASpheroTutorialText {
    static let spheroLabel = "Tilting Sphero moves"
    static let sphero2ndLabel = "your car"
    static let sphero3rdLabel = "Try it! 😎"
    static let spheroBrakeLabel = "Roll Sphero"
    static let spheroBrake2ndLabel = "towards you"
    static let spheroBrake3rdLabel = "to brake"
}

class MVATutorialSpheroNode: MVATutorialNode {
    
    override class func new(size: CGSize) -> MVATutorialSpheroNode {
        let newNode = MVATutorialSpheroNode()
        newNode.dispSize = size
        
        let swipeLabel = MVATutorialNode.label(withText: MVASpheroTutorialText.spheroLabel, andName: "swipe")
        swipeLabel.position = CGPoint(x: 0.0, y: (size.height/2.3)-newNode.iphoneXTopNotch)
        newNode.addChild(swipeLabel)
        
        let swipe2ndLabel = MVATutorialNode.label(withText: MVASpheroTutorialText.sphero2ndLabel, andName: "swipe")
        swipe2ndLabel.position = CGPoint(x: 0.0, y: swipeLabel.frame.minY-20)
        newNode.addChild(swipe2ndLabel)
        
        let swipe3rdLabel = MVATutorialNode.label(withText: MVASpheroTutorialText.sphero3rdLabel, andName: "swipe")
        swipe3rdLabel.position = CGPoint(x: 0.0, y: swipe2ndLabel.frame.minY-30)
        newNode.addChild(swipe3rdLabel)

        let gradient = SKSpriteNode(imageNamed: "grad")
        gradient.size = CGSize(width: size.width, height: size.height/2)
        gradient.anchorPoint.y = 0.0
        gradient.position = CGPoint(x: 0.0, y: 0-newNode.iphoneXTopNotch)
        gradient.zPosition = -1
        newNode.addChild(gradient)
        if newNode.iphoneXTopNotch > 0 {
            let node = SKSpriteNode(color: .black, size: CGSize(width: size.width, height: newNode.iphoneXTopNotch))
            node.anchorPoint.y = 1.0
            node.position.x = 0.0
            node.position.y = size.height/2
            node.zPosition = 1
            newNode.addChild(node)
        }
        
        return newNode
    }
        
    override func continueToBraking() {
        let labels = children.filter({ $0.name == "swipe" })
        labels.forEach({ $0.run(SKAction.fadeOut(withDuration: 0.1), completion: { self.removeChildren(in: labels) }) })
        
        if self.stage < 3 {
            self.stage = 2
        }
        
        if children.filter({ $0.name == "done" }).isEmpty {
            let wellDLabel = MVATutorialNode.label(withText: "👍", andName: nil)
            wellDLabel.verticalAlignmentMode = .top
            wellDLabel.fontSize = 66
            wellDLabel.position = CGPoint(x: 0.0, y: (dispSize.height/2.3)-iphoneXTopNotch)
            wellDLabel.alpha = 0.0
            wellDLabel.name = "done"
            addChild(wellDLabel)
            
            let presentBrakeInstructs = SKAction.run {                
                let bNode = SKNode()
                bNode.name = "brake"
                
                let brakeLabel = MVATutorialNode.label(withText: MVASpheroTutorialText.spheroBrakeLabel, andName: nil)
                brakeLabel.position = CGPoint(x: 0.0, y: (self.dispSize.height/2.3)-self.iphoneXTopNotch)
                bNode.addChild(brakeLabel)
                
                let brake2ndLabel = MVATutorialNode.label(withText: MVASpheroTutorialText.spheroBrake2ndLabel, andName: nil)
                brake2ndLabel.position = CGPoint(x: 0.0, y: brakeLabel.frame.minY-26)
                bNode.addChild(brake2ndLabel)
                
                let brake3ndLabel = MVATutorialNode.label(withText: MVASpheroTutorialText.spheroBrake3rdLabel, andName: nil)
                brake3ndLabel.position = CGPoint(x: 0.0, y: brake2ndLabel.frame.minY-19)
                bNode.addChild(brake3ndLabel)
                
                bNode.alpha = 0.0
                self.addChild(bNode)
                bNode.run(SKAction.fadeIn(withDuration: 0.1), completion: { self.stage = 3 })
            }
            
            wellDLabel.run(SKAction.sequence([SKAction.fadeIn(withDuration: 0.1),
                                              SKAction.wait(forDuration: 1.5),
                                              SKAction.fadeOut(withDuration: 0.1),
                                              presentBrakeInstructs]))
        }
    }
}
