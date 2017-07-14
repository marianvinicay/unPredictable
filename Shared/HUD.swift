//
//  HUD.swift
//  (un)Predictable
//
//  Created by Majo on 28/06/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

class HUDLabel: SKSpriteNode {
    var label: SKLabelNode {
        return self.childNode(withName: "label") as! SKLabelNode
    }
    var label1: SKLabelNode? {
        return self.childNode(withName: "label1") as? SKLabelNode
    }
    var label2: SKLabelNode? {
        return self.childNode(withName: "label2") as? SKLabelNode
    }
}

extension GameScene {
    func setDistance(_ numStr: String) {
        let decIndex = numStr.index(numStr.startIndex, offsetBy: 4)
        let normalNum = numStr.substring(to: decIndex)
        let decimNum = numStr.substring(with: decIndex..<numStr.endIndex)
        distanceSign.label.text = normalNum
        distanceSign.label1?.text = decimNum
        if Locale.current.usesMetricSystem {
            distanceSign.label2?.text = "KM"
        } else {
            distanceSign.label2?.text = "MI"
        }
        //distanceSign.label1?.text = String(dist-Int(dist))+"."
    }
    
    func setLevelSpeed(_ spd: Int) {
        speedSign.label.text = String(spd/5) //to miles !!!
    }
    
    func showHUD() {
        let showAct = SKAction.run {
            self.distanceSign.run(SKAction.moveTo(y: self.distanceSign.position.y+self.distanceSign.frame.height, duration: 0.8))
            self.speedSign.run(SKAction.moveTo(y: self.speedSign.position.y-self.speedSign.frame.height, duration: 0.8))
        }
        self.run(showAct)
    }
    
    func hideHUD(animated: Bool) {
        if animated {
            let hideAct = SKAction.run {
                self.distanceSign.run(SKAction.moveTo(y: self.distanceSign.position.y-self.distanceSign.frame.height, duration: 0.8))
                self.speedSign.run(SKAction.moveTo(y: self.speedSign.position.y+self.speedSign.frame.height, duration: 0.8))
            }
            self.run(hideAct)
        } else {
            self.distanceSign.position.y = self.distanceSign.position.y-self.distanceSign.frame.height
            self.speedSign.position.y = self.speedSign.position.y+self.speedSign.frame.height
        }
    }
}
