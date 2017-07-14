//
//  GameSceneTouch.swift
//  (un)Predictable
//
//  Created by Majo on 25/06/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//
#if os(iOS) || os(tvOS)
    import SpriteKit
    import UIKit
    
    // Touch-based event handling
    extension GameScene: UIGestureRecognizerDelegate {
        
        override func didMove(to view: SKView) {
            setupSwipes()
        }
        
        func setupSwipes() {
            let right = UISwipeGestureRecognizer(target: self, action: #selector(handelUISwipe(swipe:)))
            right.direction = .right
            
            let left = UISwipeGestureRecognizer(target: self, action: #selector(handelUISwipe(swipe:)))
            left.direction = .left
            
            let brake = UILongPressGestureRecognizer(target: self, action: #selector(handleUIBrake(gest:)))
            brake.minimumPressDuration = 0.08
            
            right.delegate = self
            left.delegate = self
            brake.delegate = self
            
            view?.addGestureRecognizer(right)
            view?.addGestureRecognizer(left)
            view?.addGestureRecognizer(brake)
        }
        
        func handelUISwipe(swipe: UISwipeGestureRecognizer) {
            switch swipe.direction {
            case UISwipeGestureRecognizerDirection.right: handleSwipe(swipe: .right)
            case UISwipeGestureRecognizerDirection.left: handleSwipe(swipe: .left)
            default: break
            }
        }

        func handleUIBrake(gest: UILongPressGestureRecognizer) {
            switch gest.state {
            case .began:
                handleBrake(started: true)
                lastPressedXPosition = gest.location(in: view).x
            case .changed:
                if lastPressedXPosition+75 < gest.location(in: view).x {
                    handleSwipe(swipe: .right)
                    lastPressedXPosition = gest.location(in: view).x
                } else if lastPressedXPosition-75 > gest.location(in: view).x {
                    handleSwipe(swipe: .left)
                    lastPressedXPosition = gest.location(in: view).x
                }
            case .ended: handleBrake(started: false)
            default: break
            }
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            if !intel.player.hasActions() && playBtt.contains(touches.first!.location(in: self)) {
                self.startGame()
            }
        }
    }
#endif
