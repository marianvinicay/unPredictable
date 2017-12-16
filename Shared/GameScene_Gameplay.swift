//
//  GameSceneTouch.swift
//  (un)Predictable
//
//  Created by Majo on 25/06/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//
import SpriteKit
#if os(iOS)
    import FirebaseAnalytics
#endif

extension GameScene: MVATutorialDelegate {
    
    func activateSwipe() {
        self.gameControls = .swipe
        self.setupSwipes()
    }
    
    func activateTilt() {
        self.gameControls = .precise
        self.setupTilt()
    }
    
    func prepareTilt() {
        #if os(iOS)
            if let quat = (UIApplication.shared.delegate as! AppDelegate).motionManager.deviceMotion?.attitude.quaternion {
                self.lastRotation = atan2(2*(quat.y*quat.w - quat.x*quat.z), 1 - 2*quat.y*quat.y - 2*quat.z*quat.z)
            }
        #endif
    }
    
    func startGame() {
        if !MVAMemory.tutorialDisplayed {
            self.gameControls = .swipe
        }
        self.physicsWorld.speed = 1.0
        let targetY = (self.size.height/2)-MVAConstants.baseCarSize.height
        let laneCount = UInt32(lanePositions.count)
        let randLane = self.gameControls == .precise ? 1:Int(arc4random_uniform(laneCount))
        let randLanePos = self.gameControls == .precise ? 0.0:CGFloat(lanePositions[randLane]!)
        let whereToGo = CGPoint(x: randLanePos, y: targetY)
        let angle = atan2(intel.player.position.y - whereToGo.y, intel.player.position.x - whereToGo.x)+CGFloat(Double.pi*0.5)
        
        NotificationCenter.default.post(name: MVAGameCenterHelper.toggleBtts, object: nil)
        startSound()
        intel.player.pointsPerSecond = intel.currentLevel.playerSpeed
        
        let turnIn = SKAction.sequence([SKAction.wait(forDuration: 0.6),SKAction.rotate(toAngle: angle, duration: 0.2)])
        let moveIn = SKAction.sequence([SKAction.wait(forDuration: 0.7),SKAction.moveTo(x: randLanePos, duration: 0.7)])
        let turnOut = SKAction.sequence([SKAction.wait(forDuration: 1.3),SKAction.rotate(toAngle: 0, duration: 0.2)])
        
        intel.player.currentLane = randLane
        intel.player.position.x = 0.0
        intel.player.run(SKAction.group([turnIn,moveIn,turnOut]))
        setLevelSpeed(intel.currentLevel.playerSpeed)
        
        let curtainUp = SKAction.run {
            if MVAMemory.tutorialDisplayed {
                self.spawnWithDelay(self.intel.currentLevel.spawnRate)
                self.showHUD()
            } else {
                self.tutorialNode = MVATutorialNode.new(size: self.size)
                self.tutorialNode?.delegate = self
                self.tutorialNode?.delegate?.activateSwipe()
                self.tutorialNode!.alpha = 0.0
                self.tutorialNode!.zPosition = 9.0
                self.camera!.addChild(self.tutorialNode!)
                self.tutorialNode!.run(SKAction.sequence([SKAction.wait(forDuration: 0.7),
                                                          SKAction.fadeIn(withDuration: 0.2)]), completion: { self.isUserInteractionEnabled = true })
            }
            self.recordDistance.run(SKAction.scale(to: 0.0, duration: 0.8))
            self.camera!.childNode(withName: "over")?.run(SKAction.fadeOut(withDuration: 0.9))
            
            #if os(iOS)
                if let quat = (UIApplication.shared.delegate as! AppDelegate).motionManager.deviceMotion?.attitude.quaternion {
                    self.lastRotation = atan2(2*(quat.y*quat.w - quat.x*quat.z), 1 - 2*quat.y*quat.y - 2*quat.z*quat.z)
                }
            #endif
        }
        
        let start = SKAction.run {
            self.gameStarted = true
            self.intel.stop = false
            
            if MVAMemory.tutorialDisplayed {
                self.intel.updateDist = true
                self.isUserInteractionEnabled = true
            }
        }
        
        playBtt.run(SKAction.sequence([SKAction.group([SKAction.scale(to: 0.0, duration: 1.0),curtainUp]),SKAction.wait(forDuration: 0.6),start]))
        /*
        #if os(macOS)
            if gameControls == .precise {
                NSCursor.hide()
            }
        #endif
        */
    }
    
    func pauseGame(withAnimation anim: Bool) {
        if !isPaused {
            self.intel.stop = true
            physicsWorld.speed = 0.0
            self.hideHUD(animated: anim)
            self.fadeOutVolume()
            if anim {
                self.playBtt.setScale(0.0)
                self.recordDistance.setScale(0.0)
                if self.tutorialNode != nil {
                   self.tutorialNode?.run(SKAction.fadeOut(withDuration: 0.5))
                }
                self.camera!.childNode(withName: "over")?.run(SKAction.fadeIn(withDuration: 0.5))
                self.recordDistance.run(SKAction.scale(to: 1.0, duration: 0.6))
                self.playBtt.run(SKAction.scale(to: 1.0, duration: 0.6), completion: {
                    self.isPaused = true
                    NotificationCenter.default.post(name: MVAGameCenterHelper.toggleBtts, object: nil)
                })
            } else {
                self.playBtt.setScale(1.0)
                self.recordDistance.setScale(1.0)
                self.camera!.childNode(withName: "over")?.alpha = 1.0
                NotificationCenter.default.post(name: MVAGameCenterHelper.toggleBtts, object: nil)
                self.isPaused = true
            }
            if MVAMemory.maxPlayerDistance < intel.distanceTraveled {
                let maxDist = intel.distanceTraveled.roundTo(NDecimals: 1)
                self.recordDistance.text = "BEST: \(maxDist) \(MVAWorldConverter.lengthUnit)"
            }
            /*
            #if os(macOS)
                if gameControls == .precise {
                    NSCursor.unhide()
                }
            #endif
            */
        }
    }
    
    func resumeGame() {
        self.isPaused = false
        NotificationCenter.default.post(name: MVAGameCenterHelper.toggleBtts, object: nil)
        self.camera!.childNode(withName: "over")?.run(SKAction.fadeOut(withDuration: 0.5))
        if self.tutorialNode != nil {
            self.tutorialNode?.run(SKAction.fadeIn(withDuration: 0.5))
        } else {
            self.showHUD()
        }
        self.recordDistance.run(SKAction.scale(to: 0.0, duration: 0.6))
        self.playBtt.run(SKAction.group([SKAction.scale(to: 0.0, duration: 0.6)]), completion: {
            self.physicsWorld.speed = 1.0
            self.intel.stop = false
            self.fadeInVolume()
        })
        
        /*
        #if os(macOS)
            if gameControls == .precise {
                NSCursor.hide()
            }
        #endif
        */
    }
    
    func gameOver() {
        if self.camera!.childNode(withName: "gameO") == nil {
            #if os(iOS) || os(tvOS)
            var offP = false
            var offAd = false
            var clumsy = true
            if tutorialNode == nil {
                if intel.distanceTraveled < 8.0 {
                    timesCrashed += 1
                }
                if timesCrashed > 2 && intel.distanceTraveled < 10.0 {
                    offAd = true
                    offP = false
                } else if MVAMemory.maxPlayerDistance > 10.0 && intel.distanceTraveled > MVAMemory.maxPlayerDistance {
                    offAd = false
                    offP = intel.storeHelper.canBuyLife()
                    clumsy = false
                }
            } else {
                tutorialNode!.run(SKAction.fadeIn(withDuration: 0.1))
                tutorialNode!.removeFromParent()
                tutorialNode = nil
            }
            #elseif os(macOS)
                var offP = false
                let offAd = false
                var clumsy = true
                if tutorialNode == nil {
                    if intel.distanceTraveled < 8.0 {
                        timesCrashed += 1
                    }
                    if timesCrashed > 2 && intel.distanceTraveled < 10.0 {
                        offP = intel.storeHelper.canBuyLife()
                    } else if MVAMemory.maxPlayerDistance > 10.0 && intel.distanceTraveled > MVAMemory.maxPlayerDistance {
                        offP = intel.storeHelper.canBuyLife()
                        clumsy = false
                    }
                } else {
                    tutorialNode!.run(SKAction.fadeIn(withDuration: 0.1))
                    tutorialNode!.removeFromParent()
                    tutorialNode = nil
                }

                /*
                if gameControls == .precise {
                    NSCursor.unhide()
                }
                */
            #endif
            
            let goNode = MVAGameOverNode.new(size: self.size, offerPurchase: offP, offerAd: offAd, clumsy: clumsy)
            goNode.zPosition = 9.0
            goNode.position = .zero
            goNode.store = intel.storeHelper
            goNode.name = "gameO"
            goNode.completion = { [unowned self] (purchased: Bool) in
                if purchased {
                    self.continueInGame()
                } else {
                    self.resetGame()
                }
            }
            
            let curtainDown = SKAction.run {
                self.removeAction(forKey: "spawn")
                self.camera!.addChild(goNode)
                self.camera!.childNode(withName: "over")?.run(SKAction.fadeIn(withDuration: 0.5))
                self.fadeOutVolume()
                goNode.performCountDown()
            }
            
            self.run(curtainDown)
            
            checkAchievements()
            
            #if os(iOS)
                Analytics.logEvent("game_over", parameters: ["level":intel.currentLevel.level])
            #endif
            
            //self.run(SKAction.sequence([SKAction.group([SKAction.wait(forDuration: 1.5),curtainDown]),resetAction]))
        }
    }
    
    func continueInGame() {
        pauseGame(withAnimation: false)
        removeChildren(in: self.children.filter({ $0.name == "smoke" }))
        camera!.childNode(withName: "nBest")?.removeFromParent()
        playerBraking = false
        spawner.size.height = MVAConstants.baseCarSize.height*2.5
        
        intel.cars.forEach({
            $0.removeFromParent()
        })
        intel.cars.removeAll()
        
        setLevelSpeed(intel.currentLevel.playerSpeed)
        spawnWithDelay(intel.currentLevel.spawnRate)
        
        checkLives()
        intel.player.resetPhysicsBody()
        intel.player.zRotation = 0
        intel.player.position.x = CGFloat(lanePositions[intel.player.currentLane]!)
        intel.player.pointsPerSecond = intel.currentLevel.playerSpeed
        startSound()
        
        /*
        #if os(macOS)
            if gameControls == .precise {
                NSCursor.hide()
            }
        #endif
        */
    }
    
    func resetGame() {
        self.removeChildren(in: self.children.filter({ $0.name == "smoke" }))
        self.camera!.childNode(withName: "nBest")?.removeFromParent()
        camera!.childNode(withName: "road")?.removeFromParent()
        camera!.position = .zero
        
        self.recordDistance.setScale(1.0)
        self.playBtt.setScale(1.0)
        
        lastUpdate = nil
        gameStarted = false
        playerDistance = "0.0"
        playerBraking = false
        newBestDisplayed = false
        roadNodes.forEach({
            $0.removeFromParent()
            roadNodes.remove($0)
        })
        
        setLevelSpeed(0)
        setDistance(MVAWorldConverter.distanceToOdometer(0.0))
        intel.reset()
        
        endOfWorld = 0.0
        spawnStartRoad()
        spawnPlayer()
        
        spawner.size.height = MVAConstants.baseCarSize.height*2.5
        remover.position = CGPoint(x: 0.0, y: -frame.height)
        NotificationCenter.default.post(name: MVAGameCenterHelper.toggleBtts, object: nil)
    }
    
    func checkAchievements() {
        if MVAMemory.maxPlayerDistance < intel.distanceTraveled {
            let maxDist = intel.distanceTraveled.roundTo(NDecimals: 1)
            MVAMemory.maxPlayerDistance = maxDist
            intel.gameCHelper.report(distance: maxDist)
            self.recordDistance.text = "BEST: \(maxDist) \(MVAWorldConverter.lengthUnit)"
        }
        let newDist = MVAMemory.accumulatedDistance + intel.distanceTraveled
        MVAMemory.accumulatedDistance = newDist
        
        let newCC = MVAMemory.crashedCars+Int64(1)
        MVAMemory.crashedCars = newCC
        if MVAMemory.enableGameCenter {
            let distToCompare = Locale.current.usesMetricSystem ? newDist:MVAWorldConverter.milesToKilometers(newDist)
            
            if distToCompare > 42.2 {
                if distToCompare > 12_742 {
                     intel.gameCHelper.report(achievement: MVAAchievements.aroundEarth)
                } else {
                    intel.gameCHelper.report(achievement: MVAAchievements.marathon)
                }
            }
            
            intel.gameCHelper.report(crashedCars: newCC)
            switch newCC {
            case 1: intel.gameCHelper.report(achievement: MVAAchievements.firstCrash)
            case 100: intel.gameCHelper.report(achievement: MVAAchievements.crashed100Cars)
            default: break
            }
        }
    }
    
    func checkLives() {
        switch intel.player.skin.name {
        case MVACarNames.playerLives:
            intel.playerLives = 3
            changeDistanceColor(MVAColor.jGreen)
            lives.isHidden = false
            battery.isHidden = true
            for child in lives.children {
                child.alpha = 1.0
            }
        case MVACarNames.playerPCS:
            intel.playerLives = 3
            changeDistanceColor(MVAColor.mvRed)
            lives.isHidden = true
            battery.isHidden = false
            for child in battery.children {
                child.removeAllActions()
                child.alpha = 1.0
            }
        default:
            intel.playerLives = -1
            changeDistanceColor(MVAColor.normBeige)
            lives.isHidden = true
            battery.isHidden = true
        }
    }
    
    @objc func addToBattery() {
        if let battBefore = battery.childNode(withName: "batt\(intel.playerLives)") {
            battBefore.removeAllActions()
            battBefore.alpha = 1.0
        }
        intel.playerLives += 1
        batteryTime = 6.0
    }
    
    func removeLife() {
        intel.playerLives -= 1
        switch intel.player.skin.name {
        case MVACarNames.playerLives: lives.childNode(withName: "life\(intel.playerLives)")?.run(SKAction.fadeOut(withDuration: 0.4))
        case MVACarNames.playerPCS:
            let battBlink = SKAction.sequence([SKAction.fadeOut(withDuration: 0.01),
                                               SKAction.wait(forDuration: 0.3),
                                               SKAction.fadeIn(withDuration: 0.01),
                                               SKAction.wait(forDuration: 0.3)])
            let battAct = SKAction.sequence([SKAction.repeat(battBlink, count: 2),
                                             SKAction.fadeOut(withDuration: 0.01)])
            
            if let battBefore = battery.childNode(withName: "batt\(intel.playerLives+1)") {
                battBefore.removeAllActions()
                battBefore.alpha = 0.0
            }
            self.batteryTime = 6.0
            battery.childNode(withName: "batt\(intel.playerLives)")?.run(battAct)
        default: break
        }
    }
}
