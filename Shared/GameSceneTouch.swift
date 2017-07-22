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
            if !gameStarted /*&& playBtt.contains(touches.first!.location(in: self))*/ {
                self.isUserInteractionEnabled = false
                //self.gameCHelper.showGKGameCenterViewController(viewController: (self.view!.window!.rootViewController as! GameViewController))
                self.startGame()
            } else if gameStarted && pauseBtt.contains(touches.first!.location(in: self.camera!)) {
                if !isPaused {
                    self.intel.stop = true
                    physicsWorld.speed = 0.0
                    self.playBtt.setScale(0.0)
                    self.hideHUD(animated: true)
                    self.camera!.childNode(withName: "over")?.run(SKAction.fadeIn(withDuration: 0.5))
                    self.playBtt.run(SKAction.scale(to: 1.0, duration: 0.6), completion: {
                        self.isPaused = true
                    })
                }
            } else if gameStarted && playBtt.contains(touches.first!.location(in: self.camera!)) {
                if isPaused {
                    self.isPaused = false
                    self.camera!.childNode(withName: "over")?.run(SKAction.fadeOut(withDuration: 0.5))
                    self.showHUD()
                    self.playBtt.run(SKAction.group([SKAction.scale(to: 0.0, duration: 0.6)]), completion: {
                        self.physicsWorld.speed = 1.0
                        self.intel.stop = false
                    })
                }
            }
        }
    }
#endif
