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

extension GameScene: UIGestureRecognizerDelegate, RKResponseObserver {
    
    override func didMove(to view: SKView) {
        switch gameControls {
        case .swipe: setupSwipes()
        case .precise:
            if (UIApplication.shared.delegate as! AppDelegate).motionManager.isDeviceMotionAvailable {
                setupTilt()
            } else {
                gameControls = .swipe
                setupSwipes()
            }
        case .sphero: setupSphero()
        }
    }
    
    func setupTilt() {
        clearControls()
        
        let brake = UILongPressGestureRecognizer(target: self, action: #selector(handleUIBrake(gest:)))
        brake.minimumPressDuration = 0.08
        brake.delegate = self
        self.view?.addGestureRecognizer(brake)
    }
    
    func startTilt() {
        let manager = (UIApplication.shared.delegate as! AppDelegate).motionManager
        manager.deviceMotionUpdateInterval = 0.06
        manager.startDeviceMotionUpdates(to: .main) { [unowned self] (data: CMDeviceMotion?, error: Error?) in
            if self.gameStarted && !self.intel.player.pcsProcessing, let quat = data?.attitude.quaternion {
                let angle = atan2(2*(quat.y*quat.w - quat.x*quat.z), 1 - 2*quat.y*quat.y - 2*quat.z*quat.z)*(180/Double.pi)
                let pitch = atan2(2*(quat.x*quat.w + quat.y*quat.z), 1 - 2*quat.x*quat.x - 2*quat.z*quat.z)*(180/Double.pi)
                
                if self.lastAngle != nil {
                    let deltaAngle = pitch > 96 ? CGFloat(angle - self.lastAngle!)*(-13):CGFloat(angle - self.lastAngle!)*13
                    if fabs(deltaAngle) > 0.3 {
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            self.handlePreciseMove(withDeltaX: deltaAngle*3.4)
                        } else { //phone
                            self.handlePreciseMove(withDeltaX: deltaAngle)
                        }
                    }
                }
                self.lastAngle = angle
            }
        }
    }
    
    func stopTilt() {
        (UIApplication.shared.delegate as! AppDelegate).motionManager.stopDeviceMotionUpdates()
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
    
    func setupSphero() {
        clearControls()
    }
    
    func startSphero() {
        UIApplication.shared.isIdleTimerDisabled = true
        let mask = RKDataStreamingMask.accelerometerXFiltered.rawValue | RKDataStreamingMask.imuPitchAngleFiltered.rawValue
        sphero?.enableSensors(RKDataStreamingMask(rawValue: mask), at: RKStreamingRate.dataStreamingRate20)
    }
    
    func stopSphero() {
        sphero?.disableSensors()
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    private func clearControls() {
        (UIApplication.shared.delegate as! AppDelegate).motionManager.stopDeviceMotionUpdates()
        self.sphero?.disableSensors()
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
            handlePreciseMove(withDeltaX: change*9)
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
    
    func handle(_ message: RKAsyncMessage!, forRobot robot: RKRobotBase!) {
        if self.gameStarted && !self.intel.player.pcsProcessing, let sensorMessage = message as? RKDeviceSensorsAsyncData {
            let sensorData = sensorMessage.dataFrames.last as? RKDeviceSensorsData

            let pitch = Double(sensorData?.attitudeData?.pitch ?? 0)
            let angle = Double(sensorData?.accelerometerData.acceleration.x ?? 0)
            
            if self.lastAngle != nil {
                let deltaAngle = CGFloat(angle - self.lastAngle!)
                let fabsDAngle = fabs(deltaAngle)
                /*if fabs(deltaAngle) > 81.0 {
                    deltaAngle *= -1
                    pitch *= -1
                }*/
                
                if fabsDAngle > 0.009 {
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        self.handlePreciseMove(toX: CGFloat(angle*469))
                    } else { //phone
                        self.handlePreciseMove(toX: CGFloat(angle*176))
                    }
                }
            }
            self.lastAngle = angle

            //brakes
            if !self.intel.playerBraking && pitch > 20.0 {
                self.handleBrake(started: true)
            } else if self.intel.playerBraking && pitch < 20.0 {
                self.handleBrake(started: false)
            }
        }
    }
}
