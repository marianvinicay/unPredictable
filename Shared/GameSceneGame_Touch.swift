//
//  GameSceneTouch.swift
//  (un)Predictable
//
//  Created by Majo on 25/06/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//
import SpriteKit

extension GameScene {
    func pauseGame(withAnimation anim: Bool) {
        if !isPaused {
            self.intel.stop = true
            physicsWorld.speed = 0.0
            self.hideHUD(animated: anim)
            self.fadeOutVolume()
            if anim {
                self.playBtt.setScale(0.0)
                self.recordDistance.setScale(0.0)
                self.camera!.childNode(withName: "over")?.run(SKAction.fadeIn(withDuration: 0.5))
                self.recordDistance.run(SKAction.scale(to: 1.0, duration: 0.6))
                self.playBtt.run(SKAction.scale(to: 1.0, duration: 0.6), completion: {
                    NotificationCenter.default.post(name: MVAGameCenterHelper.toggleBtts, object: nil)
                    self.isPaused = true
                })
            } else {
                self.playBtt.setScale(1.0)
                self.recordDistance.setScale(1.0)
                self.camera!.childNode(withName: "over")?.alpha = 1.0
                self.isPaused = true
                NotificationCenter.default.post(name: MVAGameCenterHelper.toggleBtts, object: nil)
            }
            if MVAMemory.maxPlayerDistance < intel.distanceTraveled {
                let maxDist = intel.distanceTraveled.roundTo(NDecimals: 1)
                self.recordDistance.text = "BEST: \(maxDist) \(MVAWorldConverter.lengthUnit)"
            }
        }
    }
    
    func resumeGame() {
        self.isPaused = false
        NotificationCenter.default.post(name: MVAGameCenterHelper.toggleBtts, object: nil)
        self.camera!.childNode(withName: "over")?.run(SKAction.fadeOut(withDuration: 0.5))
        self.showHUD()
        self.recordDistance.run(SKAction.scale(to: 0.0, duration: 0.6))
        self.playBtt.run(SKAction.group([SKAction.scale(to: 0.0, duration: 0.6)]), completion: {
            self.physicsWorld.speed = 1.0
            self.intel.stop = false
            self.fadeInVolume()
        })
    }
}

#if os(iOS) || os(tvOS)
    // MARK: - Touch handling
    import UIKit
    
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
                let change = gest.location(in: view).x - lastPressedXPosition
                handleBrakingSwipe(fromPositionChange: change)
                lastPressedXPosition = gest.location(in: view).x
            case .ended:
                if let currentPLane = intel.player.currentLane {
                    handleBrake(started: false)
                    let currentLanePos = CGFloat(lanePositions[currentPLane]!)
                    if intel.player.position.x != currentLanePos {
                        let actMove = SKAction.moveTo(x: currentLanePos, duration: 0.2)
                        intel.player.run(actMove)
                    }
                }
            default: break
            }
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            if !gameStarted && playBtt.contains(touches.first!.location(in: self.camera!)) {
                self.isUserInteractionEnabled = false
                self.startGame()
            } else if gameStarted && pauseBtt.contains(touches.first!.location(in: self.camera!)) {
                pauseGame(withAnimation: true)
            } else if gameStarted && playBtt.contains(touches.first!.location(in: self.camera!)) {
                resumeGame()
            }
        }
    }
#endif
