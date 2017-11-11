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
        } else if gameControls == .swipe && event.keyCode == KeyCodes.keyDown && playerBraking {
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
        touchedPosition(event.location(in: self.camera!))
        
        if gameStarted && gameControls == .precise {
            handleBrake(started: false)
        }
    }
    
    func moveWithMouse(_ mPosition: CGFloat) {
        if let mousePos = self.lastMousePos, !intel.stop {
            let deltaX = mPosition - mousePos
            let newPlayerPos = self.intel.player.position.x + deltaX
            
            if newPlayerPos >= CGFloat(lanePositions[0]!)-intel.player.size.width/1.2 &&
                newPlayerPos <= CGFloat(lanePositions[lanePositions.keys.max()!]!)+intel.player.size.width/1.2 {
                self.intel.player.position.x = newPlayerPos
                    
                let closestLane = lanePositions.enumerated().min(by: { abs(CGFloat($0.element.value) - newPlayerPos) < abs(CGFloat($1.element.value) - newPlayerPos) })!
                intel.player.currentLane = closestLane.element.key
            }
        }
        self.lastMousePos = mPosition
    }
    
    override func mouseDown(with event: NSEvent) {
        if gameStarted && !intel.stop && gameControls == .precise {
            if !playerBraking {
                handleBrake(started: true)
            }
        }
    }
    
    override func rightMouseDragged(with event: NSEvent) {
        self.lastMousePos = NSEvent.mouseLocation.x
    }
    
    override func otherMouseDragged(with event: NSEvent) {
        self.lastMousePos = NSEvent.mouseLocation.x
    }
    
    override func mouseDragged(with event: NSEvent) {
        if gameStarted && !intel.stop && gameControls == .precise {
            moveWithMouse(NSEvent.mouseLocation.x)
            if !playerBraking {
                handleBrake(started: true)
            }
        }
    }
    
    override func keyDown(with event: NSEvent) {
        interpretKeyEvents([event])
    }
    
    override func insertNewline(_ sender: Any?) {
        if self.isUserInteractionEnabled {
            if !gameStarted {
                NSCursor.hide()
                self.isUserInteractionEnabled = false
                self.startGame()
            } else {
                if isPaused {
                    self.resumeGame()
                } else {
                    self.pauseGame(withAnimation: true)
                }
            }
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
    
    override func moveDown(_ sender: Any?) {
        if gameControls == .swipe {
            handleBrake(started: true)
        }
            
    }
}
