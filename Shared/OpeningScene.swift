//
//  OpeningScene.swift
//  (un)Predictable
//
//  Created by Majo on 23/06/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import UIKit
import SpriteKit

class OpeningScene: SKScene {
    var playBtt: SKLabelNode!
    
    class func newOpeningScene(withSize deviceSize: CGSize) -> OpeningScene {
        // Load 'GameScene.sks' as an SKScene.
        //let scene = GameScene(size: size)
        guard let scene = OpeningScene(fileNamed: "OpeningScene") else {
            print("Failed to load OpeningScene.sks")
            abort()
        }
        scene.isPaused = true
        scene.speed = 0
        scene.playBtt = scene.childNode(withName: "playBtt") as! SKLabelNode
        //scene.playBtt.position.x = scene.size.width/2
        scene.scaleMode = .aspectFill
        //scene.initiateScene()
        return scene
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if playBtt.contains(touches.first!.location(in: self)) {
            self.isPaused = false
            self.speed = 1
            playBtt.run(SKAction.scale(by: 1.5, duration: 2.0), completion: {
                self.playBtt.removeFromParent()
                let trans = SKTransition.reveal(with: SKTransitionDirection.up, duration: 2.0)
                self.view?.presentScene(GameScene.newGameScene(withSize: self.scene!.size), transition: trans)
            })
            /*self.removeAction(forKey: "spawn")
            let spawn = SKAction.run {
                self.spawner.spawn(withExistingCars: self.intel.cars, roadLanes: self.intel.lanePositions)
            }
            let wait = SKAction.wait(forDuration: 1.9)
            self.run(SKAction.repeatForever(SKAction.sequence([spawn,wait])), withKey: "spawn")*/
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
}
