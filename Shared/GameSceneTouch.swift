//
//  GameSceneTouch.swift
//  (un)Predictable
//
//  Created by Majo on 25/06/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//
#if os(iOS) || os(tvOS)
    import  SpriteKit
    import  UIKit
    
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
            brake.minimumPressDuration = 0.1
            
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
                if lastPressedXPosition+65 < gest.location(in: view).x {
                    handleSwipe(swipe: .right)
                    lastPressedXPosition = gest.location(in: view).x
                } else if lastPressedXPosition-65 > gest.location(in: view).x {
                    handleSwipe(swipe: .left)
                    lastPressedXPosition = gest.location(in: view).x
                }
            case .ended: handleBrake(started: false)
            default: break
            }
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            if playBtt.contains(touches.first!.location(in: self)) {
                isPaused = false
                speed = 1
                /*let mvmnt = SKAction.moveTo(y: 180+size.height/4, duration: 2.5)
                mvmnt.timingMode = .easeOut
                cameraNode.run(mvmnt)*/
                guard let targetY = self.childNode(withName: "trgt")?.position.y else { abort() }
                let randLane = Int(arc4random_uniform(3))
                let randLanePos = intel.lanePositions[randLane]!
                let whereToGo = CGPoint(x: randLanePos, y: targetY)
                let angle = atan2(intel.player.position.y - whereToGo.y, intel.player.position.x - whereToGo.x)+CGFloat(Double.pi*0.5)
                
                let moveOut = SKAction.moveTo(y: 80, duration: 1.0)
                let turnIn = SKAction.sequence([SKAction.wait(forDuration: 0.85),SKAction.rotate(toAngle: angle, duration: 0.3)])
                let moveIn = SKAction.sequence([SKAction.wait(forDuration: 1.0),SKAction.move(to: CGPoint(x: randLanePos, y: targetY), duration: 1.0)])
                let turnOut = SKAction.sequence([SKAction.wait(forDuration: 1.85),SKAction.rotate(toAngle: 0, duration: 0.3)])
                intel.player.currentLane = randLane
                intel.player.run(SKAction.group([moveOut,turnIn,moveIn,turnOut]))
                playBtt.run(SKAction.group([SKAction.scale(by: 1.5, duration: 2.0),SKAction.fadeOut(withDuration: 2.0)]), completion: {
                    self.startGame()
                })
            }
        }
        
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        }
        
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        }
        
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        }
    }
#endif
