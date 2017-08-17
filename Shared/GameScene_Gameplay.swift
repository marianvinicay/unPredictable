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
        if MVAMemory.enableGameCenter {
            let newDist = MVAMemory.accumulatedDistance + intel.distanceTraveled
            MVAMemory.accumulatedDistance = newDist
            if newDist > 12_742 {
                intel.gameCHelper.report(achievement: MVAAchievements.aroundEarth)
            }
            
            if MVAMemory.maxPlayerDistance < intel.distanceTraveled {
                let maxDist = intel.distanceTraveled.roundTo(NDecimals: 1)
                MVAMemory.maxPlayerDistance = maxDist
                intel.gameCHelper.report(distance: maxDist)
                self.recordDistance.text = "BEST: \(maxDist) \(MVAWorldConverter.lengthUnit)"
            }
            
            let newCC = MVAMemory.crashedCars+Int64(1)
            MVAMemory.crashedCars = newCC
            intel.gameCHelper.report(crashedCars: newCC)
            switch newCC {
            case 1: intel.gameCHelper.report(achievement: MVAAchievements.firstCrash)
            default: break
            }
        }
    }
    
    func checkLives() {
        switch intel.player.skin.name {
        case "playerJeep":
            intel.playerLives = 3
            changeDistanceColor(MVAColor.jGreen)
            lives.isHidden = false
            for child in lives.children {
                child.alpha = 1.0
            }
        default:
            intel.playerLives = -1
            changeDistanceColor(MVAColor.mvRed)
            lives.isHidden = true
        }
    }
    
    func removeLife() {
        intel.playerLives -= 1
        lives.childNode(withName: "life\(intel.playerLives)")?.run(SKAction.fadeOut(withDuration: 0.4))
    }
}
