//
//  GameSceneKeyboard.swift
//  (un)Predictable
//
//  Created by Majo on 13/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

#if os(OSX)
    extension GameScene {
        
        override func keyUp(with event: NSEvent) {
            if playerBraking {
                handleBrake(started: false)
            }
        }
        
        override func keyDown(with event: NSEvent) {
            interpretKeyEvents([event])
        }
        
        override func moveLeft(_ sender: Any?) {
            handleSwipe(swipe: .left)
        }
        
        override func moveRight(_ sender: Any?) {
            handleSwipe(swipe: .right)
        }
        
        override func moveDown(_ sender: Any?) {
            handleBrake(started: true)
        }
        
        override func insertNewline(_ sender: Any?) {
            startGame()
        }
    }
#endif
