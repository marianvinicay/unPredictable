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
    
    private func startControls() {
        #if os(iOS)
        switch self.gameControls {
        case .precise: self.startTilt()
        case .sphero: self.startSphero()
        default: break
        }
        
        #elseif os(macOS)
        pauseBtt.isHidden = gameControls == .precise
        if gameControls == .precise {
            NSCursor.hide()
        }
        #endif
    }
    
    private func stopControls() {
        #if os(iOS)
        self.stopTilt()
        self.stopSphero()
        self.lastAngle = nil
        #elseif os(macOS)
        if gameControls == .precise {
            NSCursor.unhide()
        }
        #endif
    }
    
    private func handleTutorial() {
        #if os(iOS)
        let tutDisplayed = self.gameControls != .sphero ? MVAMemory.tutorialDisplayed : MVAMemory.spheroTutorialDisplayed
        if tutDisplayed {
            self.spawnWithDelay(self.intel.currentLevel.spawnRate)
            self.showHUD()
        } else {
            self.tutorialNode = self.gameControls != .sphero ? MVATutorialNode.new(size: self.size) : MVATutorialSpheroNode.new(size: self.size)
            self.tutorialNode!.delegate = self
            if self.gameControls != .sphero {
                self.tutorialNode!.delegate?.tutorialActivateSwipe()
            } else {
                self.tutorialNode!.delegate?.tutorialActivateSphero()
            }
            self.tutorialNode!.alpha = 0.0
            self.tutorialNode!.zPosition = 9.0
            self.camera!.addChild(self.tutorialNode!)
            self.tutorialNode!.run(SKAction.sequence([SKAction.wait(forDuration: 0.7),
                                                      SKAction.fadeIn(withDuration: 0.2)]), completion: { self.isUserInteractionEnabled = true })
        }
        #else
        if MVAMemory.tutorialDisplayed {
            self.spawnWithDelay(self.intel.currentLevel.spawnRate)
            self.showHUD()
        } else {
            self.tutorialNode = MVATutorialNode.new(size: self.size)
            self.tutorialNode!.delegate = self
            self.tutorialNode!.delegate?.tutorialActivateSwipe()
            self.tutorialNode!.alpha = 0.0
            self.tutorialNode!.zPosition = 9.0
            self.camera!.addChild(self.tutorialNode!)
            self.tutorialNode!.run(SKAction.sequence([SKAction.wait(forDuration: 0.7),
                                                      SKAction.fadeIn(withDuration: 0.2)]), completion: { self.isUserInteractionEnabled = true })
        }
        #endif
    }
    
    func startGame() {
        if self.gameControls != .sphero && !MVAMemory.tutorialDisplayed {
            self.gameControls = .swipe
        }
        
        self.physicsWorld.speed = 1.0
        let targetY = (self.size.height/2)-MVAConstants.baseCarSize.height
        let laneCount = UInt32(lanePositions.count)
        let randLane = self.gameControls == .swipe ? Int(arc4random_uniform(laneCount)):1
        let randLanePos = self.gameControls == .swipe ? CGFloat(lanePositions[randLane]!):0.0
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
            self.handleTutorial()
            
            self.recordDistance.run(SKAction.scale(to: 0.0, duration: 0.8))
            self.camera!.childNode(withName: "over")?.run(SKAction.fadeOut(withDuration: 0.9))
            self.startControls()
        }
        
        let tutDisplayed = self.gameControls != .sphero ? MVAMemory.tutorialDisplayed : MVAMemory.spheroTutorialDisplayed
        let start = SKAction.run {
            self.gameStarted = true
            self.intel.stop = false
            
            if tutDisplayed {
                self.intel.updateDist = true
                self.isUserInteractionEnabled = true
                
                #if os(macOS)
                self.cDelegate?.showInInfoLabel("Go Go Go!", forDuration: 3.0)
                #endif
            }
        }
        
        playBtt.run(SKAction.sequence([SKAction.group([SKAction.scale(to: 0.0, duration: 1.0),curtainUp]),SKAction.wait(forDuration: 0.6),start]))
    }
    
    func pauseGame(withAnimation anim: Bool) {
        if !isPaused {
            self.stopControls()
            
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
        }
    }
    
    func resumeGame() {
        self.startControls()
        
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
    }
    
    func gameOver() {
        if self.camera!.childNode(withName: "gameO") == nil {
            var clumsy = true
            var offP = false
            #if os(iOS)
            if tutorialNode == nil {
                if intel.distanceTraveled < 10.0 {
                    timesCrashed += 1
                }
                
                if intel.distanceTraveled > MVAMemory.maxPlayerDistance {
                    clumsy = false
                }
                
                if timesCrashed > 2 && intel.distanceTraveled < 10.0 {
                    offP = intel.storeHelper.canBuyLife()
                } else if MVAMemory.maxPlayerDistance > 10.0 {
                    offP = intel.storeHelper.canBuyLife()
                    clumsy = false
                }
            } else {
                tutorialNode!.run(SKAction.fadeIn(withDuration: 0.1))
                tutorialNode!.removeFromParent()
                tutorialNode = nil
            }
            #elseif os(macOS)
                if tutorialNode == nil {
                    if intel.distanceTraveled < 10.0 {
                        timesCrashed += 1
                    }
                    
                    if intel.distanceTraveled > MVAMemory.maxPlayerDistance {
                        clumsy = false
                    }
                    
                    if timesCrashed > 2 && intel.distanceTraveled < 10.0 {
                        offP = intel.storeHelper.canBuyLife()
                    } else if MVAMemory.maxPlayerDistance > 10.0 {
                        offP = intel.storeHelper.canBuyLife()
                        clumsy = false
                    }
                } else {
                    tutorialNode!.run(SKAction.fadeIn(withDuration: 0.1))
                    tutorialNode!.removeFromParent()
                    tutorialNode = nil
                }
            #endif
            
            let goNode = MVAGameOverNode.new(size: self.size, offerPurchase: offP, clumsy: clumsy)
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
                #if os(macOS)
                self.cDelegate?.showInInfoLabel("", forDuration: 0.0)
                #endif
            }
            
            let curtainDown = SKAction.run {
                self.stopControls()
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
        
        #if os(iOS)
        //sphero?.setLEDWithRed(0.0, green: 1.0, blue: 0.0)
        #endif
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
        
        #if os(iOS)
        //sphero?.setLEDWithRed(0.0, green: 1.0, blue: 0.0)
        #elseif os(macOS)
        self.cDelegate?.distanceChanged(toNumberString: nil)
        #endif
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
    
    func tutorialActivateSwipe() {
        self.gameControls = .swipe
        self.setupSwipes()
    }
    
    func tutorialActivateTilt() {
        self.gameControls = .precise
        self.setupTilt()
        #if os(iOS)
        self.startTilt()
        #endif
    }
    
    #if os(iOS)
    func tutorialActivateSphero() {
        self.gameControls = .sphero
        self.setupSphero()
        self.startSphero()
    }
    #endif
}
