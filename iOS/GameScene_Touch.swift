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
        if MVAMemory.gameControls == .precise && (UIApplication.shared.delegate as! AppDelegate).motionManager.isDeviceMotionAvailable {
            setupTilt()
        } else {
            setupSwipes()
        }
    }
    
    func setupTilt() {
        clearControls()
        
        let manager = (UIApplication.shared.delegate as! AppDelegate).motionManager
        manager.deviceMotionUpdateInterval = 0.01
        manager.startDeviceMotionUpdates(to: .main) { [unowned self] (data: CMDeviceMotion?, error: Error?) in
            if let quat = data?.attitude.quaternion, !self.intel.stop || !self.canUpdateSpeed {
                let angle = atan2(2*(quat.y*quat.w - quat.x*quat.z), 1 - 2*quat.y*quat.y - 2*quat.z*quat.z)*(180/Double.pi)
                let pitch = atan2(2*(quat.x*quat.w + quat.y*quat.z), 1 - 2*quat.x*quat.x - 2*quat.z*quat.z)*(180/Double.pi)
                
                if self.lastRotation != nil {
                    let deltaAngle = pitch > 96 ? CGFloat(angle - self.lastRotation!)*(-13):CGFloat(angle - self.lastRotation!)*13
                    if fabs(deltaAngle) > 0.5 {
                        if self.handlePreciseMove(withDeltaX: deltaAngle) {
                            self.lastRotation = angle
                        }
                    }
                } else {
                    self.lastRotation = angle
                }
            }
        }
        
        let brake = UILongPressGestureRecognizer(target: self, action: #selector(handleUIBrake(gest:)))
        brake.minimumPressDuration = 0.08
        brake.delegate = self
        self.view?.addGestureRecognizer(brake)
    }
    
    func setupSwipes() {
        clearControls()
        
        let right = UISwipeGestureRecognizer(target: self, action: #selector(handleUISwipe(swipe:)))
        right.direction = .right
        
        let left = UISwipeGestureRecognizer(target: self, action: #selector(handleUISwipe(swipe:)))
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
    
    private func clearControls() {
        (UIApplication.shared.delegate as! AppDelegate).motionManager.stopDeviceMotionUpdates()
        for recog in self.view?.gestureRecognizers ?? [] {
            self.view?.removeGestureRecognizer(recog)
        }
    }
    
    @objc func handleUISwipe(swipe: UISwipeGestureRecognizer) {
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
        case .changed where self.gameControls == .swipe:
            let change = gest.location(in: view).x - lastPressedXPosition
            _ = handlePreciseMove(withDeltaX: change)
            lastPressedXPosition = gest.location(in: view).x
        case .ended where self.gameControls == .swipe:
            if let currentPLane = intel.player.currentLane {
                handleBrake(started: false)
                let currentLanePos = CGFloat(lanePositions[currentPLane]!)
                if intel.player.position.x != currentLanePos && !intel.stop {
                    let actMove = SKAction.moveTo(x: currentLanePos, duration: 0.2)
                    intel.player.run(actMove)
                }
            }
        case .ended where self.gameControls == .precise:
            handleBrake(started: false)
        default: break
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.location(in: self.camera!)
        touchedPosition(point)
    }
}
