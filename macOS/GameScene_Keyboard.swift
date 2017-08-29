//
//  GameSceneKeyboard.swift
//  (un)Predictable
//
//  Created by Majo on 13/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

enum KeyCodes {
    public static let keyDown: UInt16 = 125
}
    
extension GameScene {
    
    override func keyUp(with event: NSEvent) {
        if intel.stop {
            if let goNode = self.camera?.childNode(withName: "gameO") as? MVAGameOverNode {
                if goNode.yesBtt == nil {
                    goNode.touchedPosition(.zero)
                }
            }
        } else if event.keyCode == KeyCodes.keyDown && playerBraking {
            handleBrake(started: false)
            if let currentPLane = intel.player.currentLane {
                let currentLanePos = CGFloat(lanePositions[currentPLane]!)
                if intel.player.position.x != currentLanePos && !intel.stop {
                    let actMove = SKAction.moveTo(x: currentLanePos, duration: 0.2)
                    intel.player.run(actMove)
                }
            }
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        let fPoint = self.convertPoint(fromView: event.locationInWindow)
        let point = self.convert(fPoint, to: self.camera!)
        touchedPosition(point)
    }
    
    override func keyDown(with event: NSEvent) {
        interpretKeyEvents([event])
    }
    
    override func moveUp(_ sender: Any?) {
        if !gameStarted {
            self.isUserInteractionEnabled = false
            self.startGame()
        }
    }
    
    override func moveLeft(_ sender: Any?) {
        if playerBraking {
            handleBrakingSwipe(fromPositionChange: -6, animated: true)
        } else {
            handleSwipe(swipe: .left)
        }
    }
    
    override func moveRight(_ sender: Any?) {
        if playerBraking {
            handleBrakingSwipe(fromPositionChange: 6, animated: true)
        } else {
            handleSwipe(swipe: .right)
        }
    }
    
    override func moveDown(_ sender: Any?) {
        handleBrake(started: true)
    }
}
