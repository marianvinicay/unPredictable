//
//  GameSceneKeyboard.swift
//  (un)Predictable
//
//  Created by Majo on 13/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

enum KeyCodes {
    public static let keySpacebar: UInt16 = 49
    public static let keyESC: UInt16 = 53
}
    
extension GameScene {
    
    func setupTilt() {
        self.cDelegate?.changeControls(to: .precise)
    }
    
    func setupSwipes() {
        self.cDelegate?.changeControls(to: .swipe)
    }
    
    override func keyUp(with event: NSEvent) {
        if intel.stop {
            if let goNode = self.camera?.childNode(withName: "gameO") as? MVAGameOverNode {
                if goNode.yesBtt == nil {
                    goNode.touchedPosition(.zero)
                }
            }
        } else if event.keyCode == KeyCodes.keySpacebar && playerBraking {
            handleBrake(started: false)
            if self.gameControls == .swipe, let currentLane = intel.player.currentLane {
                let currentLanePos = CGFloat(lanePositions[currentLane]!)
                if intel.player.position.x != currentLanePos && !intel.stop {
                    let actMove = SKAction.moveTo(x: currentLanePos, duration: 0.2)
                    intel.player.run(actMove)
                }
            }
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        touchedPosition(event.location(in: self.camera!))
    }
    
    func moveWithMouse(_ mPosition: CGFloat) {
        if let mousePos = self.lastMousePos, !intel.stop {
            let deltaX = mPosition - mousePos
            self.handlePreciseMove(withDeltaX: deltaX)
        }
        self.lastMousePos = mPosition
    }
    
    override func rightMouseDragged(with event: NSEvent) {
        self.lastMousePos = NSEvent.mouseLocation.x
    }
    
    override func otherMouseDragged(with event: NSEvent) {
        self.lastMousePos = NSEvent.mouseLocation.x
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.lastMousePos = NSEvent.mouseLocation.x
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case KeyCodes.keySpacebar:
            handleBrake(started: true)
        case KeyCodes.keyESC:
            if gameStarted && !isPaused {
                self.pauseGame(withAnimation: true)
            }
        default:
            interpretKeyEvents([event])
        }
    }
    
    override func moveUp(_ sender: Any?) {
        if !gameStarted {
            self.isUserInteractionEnabled = false
            self.startGame()
        }
    }
    
    override func moveLeft(_ sender: Any?) {
        if gameControls == .swipe {
            if playerBraking {
                handlePreciseMove(withDeltaX: -9, animated: true)
            } else {
                handleSwipe(swipe: .left)
            }
        }
    }
    
    override func moveRight(_ sender: Any?) {
        if gameControls == .swipe {
            if playerBraking {
                handlePreciseMove(withDeltaX: 9, animated: true)
            } else {
                handleSwipe(swipe: .right)
            }
        }
    }
}
