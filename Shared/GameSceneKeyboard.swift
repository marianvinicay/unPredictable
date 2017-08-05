//
//  GameSceneKeyboard.swift
//  (un)Predictable
//
//  Created by Majo on 13/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

#if os(macOS)
    extension GameScene {
        
        override func keyUp(with event: NSEvent) {
            if playerBraking {
                handleBrake(started: false)
            }
        }
        
        override func mouseUp(with event: NSEvent) {
            if playBtt.contains(CGPoint(x: event.absoluteX, y: event.absoluteY)) {
                startGame()
            }
        }
        
        override func keyDown(with event: NSEvent) {
            interpretKeyEvents([event])
        }
        
        override func moveLeft(_ sender: Any?) {
            if playerBraking {
                handleBrakingSwipe(fromPositionChange: -10)
            } else {
                handleSwipe(swipe: .left)
            }
        }
        
        override func moveRight(_ sender: Any?) {
            if playerBraking {
                handleBrakingSwipe(fromPositionChange: 10)
            } else {
                handleSwipe(swipe: .right)
            }
        }
        
        override func moveDown(_ sender: Any?) {
            handleBrake(started: true)
        }
        
        override func insertNewline(_ sender: Any?) {
            startGame()
        }
    }
#endif
