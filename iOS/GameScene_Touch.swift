//
//  GameScene_Touch.swift
//  unPredictable
//
//  Created by Majo on 17/08/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import UIKit
import SpriteKit
import CoreMotion

extension GameScene: UIGestureRecognizerDelegate {
    
    override func didMove(to view: SKView) {
        setupSwipes()
        setupTilt()
    }
    
    func setupTilt() {
        let manager = (UIApplication.shared.delegate as! AppDelegate).motionManager
        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = 0.01
            manager.startDeviceMotionUpdates(to: .main) { [unowned self] (data: CMDeviceMotion?, error: Error?) in
                if let attitude = data?.attitude {
                    let angle = attitude.roll*(180/Double.pi)
                    if self.lastRotation != nil {
                        let deltaAngle = CGFloat(angle - self.lastRotation!)*4
                        self.handlePreciseMove(withDeltaX: deltaAngle)
                    }
                    
                    self.lastRotation = angle
                }
            }
        }
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
    
    @objc func handelUISwipe(swipe: UISwipeGestureRecognizer) {
        switch swipe.direction {
        case UISwipeGestureRecognizerDirection.right: handleSwipe(swipe: .right)
        case UISwipeGestureRecognizerDirection.left: handleSwipe(swipe: .left)
        default: break
        }
    }
    
    @objc func handleUIBrake(gest: UILongPressGestureRecognizer) {
        switch gest.state {
        case .began:
            handleBrake(started: true)
            lastPressedXPosition = gest.location(in: view).x
        case .changed:
            let change = gest.location(in: view).x - lastPressedXPosition
            handlePreciseMove(withDeltaX: change)
            lastPressedXPosition = gest.location(in: view).x
        case .ended:
            if let currentPLane = intel.player.currentLane {
                handleBrake(started: false)
                let currentLanePos = CGFloat(lanePositions[currentPLane]!)
                if intel.player.position.x != currentLanePos && !intel.stop {
                    let actMove = SKAction.moveTo(x: currentLanePos, duration: 0.2)
                    intel.player.run(actMove)
                }
            }
        default: break
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.location(in: self.camera!)
        touchedPosition(point)
    }
}
