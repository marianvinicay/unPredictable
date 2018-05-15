//
//  HUD.swift
//  (un)Predictable
//
//  Created by Majo on 28/06/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

struct HUDLabel {
    static func giveMeLabel(fromNode node: SKSpriteNode) -> SKLabelNode {
        return node.childNode(withName: "label") as! SKLabelNode
    }
    
    static func giveMeLabel1(fromNode node: SKSpriteNode) -> SKLabelNode? {
        return node.childNode(withName: "label1") as? SKLabelNode
    }
    
    static func giveMeLabel2(fromNode node: SKSpriteNode) -> SKLabelNode? {
        return node.childNode(withName: "label2") as? SKLabelNode
    }
}

extension GameScene {
    func setDistance(_ numStr: String) {
        let decIndex = numStr.index(numStr.startIndex, offsetBy: 4)
        let normalNum = String(numStr[..<decIndex])
        let decimNum = String(numStr[decIndex..<numStr.endIndex])
        HUDLabel.giveMeLabel(fromNode: distanceSign).text = normalNum
        HUDLabel.giveMeLabel1(fromNode: distanceSign)!.text = decimNum
        HUDLabel.giveMeLabel2(fromNode: distanceSign)!.text = MVAWorldConverter.lengthUnit
    }
    
    #if os(macOS)
        func changeDistanceColor(_ color: NSColor) {
            HUDLabel.giveMeLabel1(fromNode: distanceSign)!.fontColor = color
        }
    #else
        func changeDistanceColor(_ color: UIColor) {
            HUDLabel.giveMeLabel1(fromNode: distanceSign)!.fontColor = color
        }
    #endif
    
    
    func setLevelSpeed(_ spd: Int) {
        if canUpdateSpeed {
            HUDLabel.giveMeLabel(fromNode: speedSign).text = String(MVAWorldConverter.pointsSpeedToRealWorld(spd))
        }
    }
    
    func showHUD() {
        let showAct = SKAction.run {
            self.distanceSign.run(SKAction.moveTo(y: self.originalDistancePosition.y, duration: 0.5))
            self.camera!.childNode(withName: "down")?.run(SKAction.moveTo(y: self.originalDistancePosition.y, duration: 0.5))
            self.camera!.childNode(withName: "iphoneX")?.run(SKAction.moveTo(y: -self.size.height/2, duration: 0.5))
            
            let spdAct = SKAction.moveTo(y: self.originalSpeedPosition.y, duration: 0.5)
            self.speedSign.run(spdAct)
            
            self.pauseBtt.run(SKAction.moveTo(y: self.originalPausePosition.y, duration: 0.5))
        }
        self.run(showAct)
    }
    
    func hideHUD(animated: Bool) {
        if animated {
            let hideAct = SKAction.run {
                self.distanceSign.run(SKAction.moveTo(y: self.distanceSign.position.y-(self.distanceSign.size.height*2), duration: 0.5))
            
                self.camera!.childNode(withName: "down")!.run(SKAction.moveTo(y: self.distanceSign.position.y-(self.distanceSign.size.height*2), duration: 0.5))
                self.camera!.childNode(withName: "iphoneX")?.run(SKAction.moveTo(y: self.distanceSign.position.y-(self.distanceSign.size.height*2), duration: 0.5))
                self.camera!.childNode(withName: "nBest")?.run(SKAction.moveTo(y: self.distanceSign.position.y-(self.distanceSign.size.height*2), duration: 0.5))
                
                self.speedSign.run(SKAction.moveTo(y: self.speedSign.position.y+(self.speedSign.size.height*2), duration: 0.5))
                self.pauseBtt.run(SKAction.moveTo(y: self.pauseBtt.position.y+(self.pauseBtt.size.height*2), duration: 0.5))
            }
            self.run(hideAct)
        } else {
            self.distanceSign.position.y = self.distanceSign.position.y-(self.distanceSign.size.height*2)
            
            self.camera!.childNode(withName: "down")?.position.y = self.distanceSign.position.y
            self.camera!.childNode(withName: "iphoneX")?.position.y = self.distanceSign.position.y
            self.camera!.childNode(withName: "nBest")?.position.y = self.distanceSign.position.y
            
            self.speedSign.position.y = self.speedSign.position.y+(self.speedSign.size.height*2)
            self.pauseBtt.position.y = self.pauseBtt.position.y+(self.pauseBtt.size.height*2)
        }
    }
}
