//
//  GameScene.swift
//  (un)Predictable
//
//  Created by Majo on 25/08/16.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit
import Crashlytics
#if os(iOS)
import UIKit
#endif

#if os(watchOS)
    import WatchKit
    // <rdar://problem/26756207> SKColor typealias does not seem to be exposed on watchOS SpriteKit
    typealias SKColor = UIColor
#endif

class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Variables
    // MARK: Gameplay Logic
    let intel = MVAMarvinAI()
    var playerDistance = "0.0"
    var gameStarted = false
    var playerBraking = false
    var timesCrashed = 0
    
    // MARK: Buttons
    var playBtt: SKSpriteNode!
    var pauseBtt: SKSpriteNode!
    var originalPausePosition: CGPoint!
    
    // MARK: Gameplay Sprites
    var speedSign: SKSpriteNode!
    var originalSpeedPosition: CGPoint!
    var distanceSign: SKSpriteNode!
    var originalDistancePosition: CGPoint!
    var recordDistance: SKLabelNode!
    var roadNodes = Set<MVARoadNode>()
    var remover: SKSpriteNode!
    var spawner: MVASpawner!
    
    // MARK: Gameplay Helpers
    var tutorialNode: MVATutorialNode?
    var lastPressedXPosition: CGFloat!
    var endOfWorld: CGFloat? = 0.0
    var brakingTimer: Timer!
    var lastUpdate: TimeInterval!
    let sound = MVASound()
    var newBestDisplayed = false
    var canUpdateSpeed = true
    private var startDate: Date?
    
    // MARK: - Gameplay
    func startGame() {
        self.physicsWorld.speed = 1.0
        let targetY = (self.size.height/2)-MVAConstants.baseCarSize.height
        let randLane = Int(arc4random_uniform(3))
        let randLanePos = CGFloat(lanePositions[randLane]!)
        let whereToGo = CGPoint(x: randLanePos, y: targetY)
        let angle = atan2(intel.player.position.y - whereToGo.y, intel.player.position.x - whereToGo.x)+CGFloat(Double.pi*0.5)
        
        NotificationCenter.default.post(name: MVAGameCenterHelper.toggleBtts, object: nil)
        startSound()
        intel.player.pointsPerSecond = intel.currentLevel.playerSpeed
        
        let turnIn = SKAction.sequence([SKAction.wait(forDuration: 0.6),SKAction.rotate(toAngle: angle, duration: 0.2)])
        let moveIn = SKAction.sequence([SKAction.wait(forDuration: 0.7),SKAction.moveTo(x: randLanePos, duration: 0.7)])
        let turnOut = SKAction.sequence([SKAction.wait(forDuration: 1.3),SKAction.rotate(toAngle: 0, duration: 0.2)])
        
        intel.player.currentLane = randLane
        intel.player.run(SKAction.group([turnIn,moveIn,turnOut]))
        setLevelSpeed(intel.currentLevel.playerSpeed)
        
        let curtainUp = SKAction.run {
            if MVAMemory.tutorialDisplayed {
                self.spawnWithDelay(self.intel.currentLevel.spawnRate)
                self.showHUD()
            } else {
                self.tutorialNode = MVATutorialNode.new(size: self.size)
                self.tutorialNode!.alpha = 0.0
                self.tutorialNode!.zPosition = 9.0
                self.camera!.addChild(self.tutorialNode!)
                self.tutorialNode!.run(SKAction.sequence([SKAction.wait(forDuration: 0.7),
                                                          SKAction.fadeIn(withDuration: 0.2)]), completion: { self.isUserInteractionEnabled = true })
            }
            self.recordDistance.run(SKAction.scale(to: 0.0, duration: 0.8))
            self.camera!.childNode(withName: "over")?.run(SKAction.fadeOut(withDuration: 0.9))
        }
        
        let start = SKAction.run {
            self.gameStarted = true
            
            if MVAMemory.tutorialDisplayed {
                self.isUserInteractionEnabled = true
                self.startDate = Date()
                self.intel.updateDist = true
            }
        }
        
        playBtt.run(SKAction.sequence([SKAction.group([SKAction.scale(to: 0.0, duration: 1.0),curtainUp]),SKAction.wait(forDuration: 0.6),start]))
    }
    
    private func gameOver() {
        if self.camera!.childNode(withName: "gameO") == nil {
            var offP = false
            if tutorialNode == nil {
                if intel.distanceTraveled < 8.0 {
                    timesCrashed += 1
                }
                if timesCrashed >= 3 && intel.distanceTraveled > 1.0 {
                    offP = true
                } else if MVAMemory.maxPlayerDistance > 10.0 && intel.distanceTraveled > MVAMemory.maxPlayerDistance {
                    offP = true
                }
            } else {
                tutorialNode!.run(SKAction.fadeIn(withDuration: 0.1))
                tutorialNode!.removeFromParent()
                tutorialNode = nil
            }
            
            let goNode = MVAGameOverNode.new(size: self.size, offerPurchase: offP)
            goNode.zPosition = 8.0
            goNode.position = .zero
            goNode.store = intel.storeHelper
            goNode.name = "gameO"
            goNode.completion = { [unowned self] (purchased: Bool) in
                if purchased {
                    self.continueInGame()
                } else {
                    if let sDate = self.startDate {
                        self.intel.healthKHelper.logTime(withStart: sDate)
                    }
                    self.resetScene()
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
            
            Answers.logCustomEvent(withName: "Ended_In_Level_\(intel.currentLevel.level)", customAttributes: nil)
            //self.run(SKAction.sequence([SKAction.group([SKAction.wait(forDuration: 1.5),curtainDown]),resetAction]))
        }
    }
    
    private func continueInGame() {
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
        
        MVACar.resetPhysicsBody(forCar: intel.player)
        intel.player.zRotation = 0
        intel.player.position.x = CGFloat(lanePositions[intel.player.currentLane]!)
        intel.player.pointsPerSecond = intel.currentLevel.playerSpeed
        startSound()
    }
    
    private func nextLevelSign(withCompletion completion: @escaping (()->())) {
        self.removeAction(forKey: "spawn")
        self.physicsWorld.speed = 0.0
        setLevelSpeed(intel.currentLevel.playerSpeed)
        self.canUpdateSpeed = false
        let rightScale = speedSign.xScale
        let signIN = SKAction.group([SKAction.scale(to: 0.3, duration: 0.4),SKAction.move(to: CGPoint.zero, duration: 0.4)])
        let signOUT = SKAction.group([SKAction.scale(to: rightScale, duration: 0.3),SKAction.move(to: originalSpeedPosition, duration: 0.3)])
        speedSign.run(SKAction.sequence([signIN,SKAction.wait(forDuration: 0.8),signOUT]), completion: {
            self.physicsWorld.speed = 1.0
            self.canUpdateSpeed = true
            completion()
        })
    }
    
    private func displayNewBest() {
        newBestDisplayed = true
        let label = SKLabelNode(fontNamed: "Futura Bold")
        label.fontSize = 20
        label.text = "New Best!"
        label.verticalAlignmentMode = .bottom
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: distanceSign.position.x+distanceSign.size.width+10, y: (-self.size.height/2)+label.frame.height)
        label.zPosition = 7.0
        label.name = "nBest"
        let addAct = SKAction.run {
            label.yScale = 0.0
            self.camera!.addChild(label)
            label.run(SKAction.scaleY(to: 1.0, duration: 0.5))
        }
        let removeAct = SKAction.run {
            label.run(SKAction.scaleY(to: 0.0, duration: 0.5)) {
                label.removeFromParent()
            }
        }
        self.camera!.run(SKAction.sequence([addAct,SKAction.wait(forDuration: 5.0),removeAct]))
    }
    
    private func spawnWithDelay(_ delay: TimeInterval) {
        self.removeAction(forKey: "spawn")
        let spawn = SKAction.run {
            self.spawner.spawnCar(withExistingCars: self.intel.cars.filter({ $0.position.y > self.camera!.position.y+self.size.height/3 }))
        }
        let wait = SKAction.wait(forDuration: delay)
        self.run(SKAction.repeatForever(SKAction.sequence([spawn,wait])), withKey: "spawn")
    }
    
    override func update(_ currentTime: TimeInterval) {
        updateCamera()
        if gameStarted {
            if lastUpdate != nil {
                intel.update(withDeltaTime: currentTime-lastUpdate)
            }
            lastUpdate = currentTime

            DispatchQueue.main.async {
                let newDistance = MVAWorldConverter.distanceToOdometer(self.intel.distanceTraveled)
                if self.playerDistance != newDistance {
                    if !self.newBestDisplayed && MVAMemory.maxPlayerDistance != 0.0 && MVAMemory.maxPlayerDistance <= self.intel.distanceTraveled {
                        self.displayNewBest()
                    }
                    self.playerDistance = newDistance
                    self.setDistance(newDistance)
                    
                    if newDistance == MVAWorldConverter.distanceToOdometer(Double(self.intel.currentLevel.nextMilestone)) && !self.playerBraking {
                        self.intel.currentLevel.level += 1
                        self.nextLevelSign {
                            if !self.playerBraking {
                                self.intel.player.changeSpeed(self.intel.currentLevel.playerSpeed)
                            }
                            self.spawnWithDelay(self.intel.currentLevel.spawnRate)
                        }
                    }
                }
            }
            
            if endOfWorld != nil {
                if MVAMemory.tutorialDisplayed && endOfWorld! < self.camera!.position.y {
                    let road = MVARoadNode.createWith(texture: spawner.roadTexture, height: self.size.height, andWidth: self.size.width)
                    road.position = .zero
                    road.name = "road"
                    camera!.addChild(road)
                    endOfWorld = nil
                    roadNodes.forEach({
                        $0.removeFromParent()
                        roadNodes.remove($0)
                    })
                } else if MVAMemory.tutorialDisplayed == false && endOfWorld!-self.size.height < self.camera!.position.y {
                    let road = MVARoadNode.createWith(texture: SKTexture(imageNamed: "Start2"), height: self.size.height, andWidth: self.size.width)
                    road.position = CGPoint(x: 0.0, y: endOfWorld!)
                    road.name = "road"
                    endOfWorld = road.position.y+road.size.height
                    roadNodes.insert(road)
                    self.addChild(road)
                }
            }
        }
    }
    
    private func updateCamera() {
        spawner.position.y = camera!.position.y+self.size.height
        if intel.player != nil {
            let desiredCameraPosition = intel.player.position.y+size.height/4
            camera!.run(SKAction.moveTo(y: desiredCameraPosition, duration: 0.02))
            //camera!.position.y = desiredCameraPosition
        }
        remover.position.y = camera!.position.y-self.size.height
    }
    
    private func endTutorial() {
        tutorialNode?.end {
            self.tutorialNode?.removeFromParent()
            self.tutorialNode = nil
            self.intel.updateDist = true
            self.startDate = Date()
            self.showHUD()
            
            MVAMemory.tutorialDisplayed = true
            
            let road = MVARoadNode.createWith(texture: self.spawner.roadTexture, height: self.size.height, andWidth: self.size.width)
            road.position = CGPoint(x: 0.0, y: self.endOfWorld!)
            road.name = "road"
            self.roadNodes.insert(road)
            self.addChild(road)
            
            if MVAMemory.enableGameCenter {
                self.intel.gameCHelper.authenticateLocalPlayer()
            }
        }
    }
    
    // MARK: - Controls
    func handleSwipe(swipe: MVAPosition) {
        if gameStarted && physicsWorld.speed != 0.0 {
            guard intel.player.mindSet == .player else { return }
            if intel.player.changeLane(inDirection: swipe, AndPlayer: intel.player) {
                sound.indicate(onNode: intel.player)
                
                if tutorialNode?.stage == 0 {
                    spawnWithDelay(intel.currentLevel.spawnRate)
                    tutorialNode!.continueToBraking()
                }
            }
        }
    }
    
    func handleBrakingSwipe(fromPositionChange posCh: CGFloat) {
        if gameStarted && physicsWorld.speed != 0.0 {
            guard tutorialNode == nil || tutorialNode?.stage != 0 else { return }
            guard intel.player.mindSet == .player else { return }
            let newPlayerPos = intel.player.position.x + posCh
            if newPlayerPos >= CGFloat(lanePositions[0]!)-intel.player.size.width/1.2 &&
                newPlayerPos <= CGFloat(lanePositions[lanePositions.keys.max()!]!)+intel.player.size.width/1.2 {
                intel.player.position.x = newPlayerPos
                let closestLane = lanePositions.enumerated().min(by: { abs(CGFloat($0.element.value) - newPlayerPos) < abs(CGFloat($1.element.value) - newPlayerPos) })!
                intel.player.currentLane = closestLane.element.key
            }
            
            if tutorialNode?.stage == 1 {
                endTutorial()
            }
        }
    }
    
    func handleBrake(started: Bool) {
        if gameStarted {
            if started {
                guard tutorialNode == nil || tutorialNode?.stage != 0 else { return }
                if playerBraking == false {
                    self.removeAction(forKey: "spawn")
                    spawner.size.height = self.size.height
                    playerBraking = true
                }
                deceleratePlayer()
            } else {
                if playerBraking == true {
                    playerBraking = false
                    spawnWithDelay(intel.currentLevel.spawnRate)
                    intel.player.brakeLight(false)
                }
                acceleratePlayer()
            }
        }
    }
    
    func acceleratePlayer() {
        if playerBraking == false {
            if intel.player.pointsPerSecond < intel.currentLevel.playerSpeed {
                let forForce = CGFloat((intel.currentLevel.playerSpeed/5)*9)
                intel.player.physicsBody!.applyForce(CGVector(dx: 0.0, dy: intel.player.physicsBody!.mass*forForce))
                if intel.player.pointsPerSecond > 150 {
                    setLevelSpeed(intel.player.pointsPerSecond)
                }
                if self.audioEngine.mainMixerNode.outputVolume < 1.0 {
                    setVolume(audioEngine.mainMixerNode.outputVolume+0.1)
                }
                self.perform(#selector(acceleratePlayer), with: nil, afterDelay: 0.01)
            } else {
                intel.player.pointsPerSecond = intel.currentLevel.playerSpeed
                setLevelSpeed(intel.currentLevel.playerSpeed)
                spawner.size.height = MVAConstants.baseCarSize.height*2.5
                setVolume(1.0)
            }
        }
    }
    
    func deceleratePlayer() {
        if playerBraking && intel.player.pointsPerSecond > MVAConstants.minimalBotSpeed-15 {
            let backForce = CGFloat((intel.currentLevel.playerSpeed/5)*13)
            intel.player.physicsBody!.applyForce(CGVector(dx: 0.0, dy: -intel.player.physicsBody!.mass*backForce))
            intel.player.brakeLight(true)
            
            var minSpeed = 150
            if let carInFront = intel.player.responseFromSensors(inPositions: [.front]).first {
                if carInFront.pointsPerSecond > 35 && carInFront.pointsPerSecond < 110 {
                    minSpeed = carInFront.pointsPerSecond
                }
            }
            if intel.player.pointsPerSecond > minSpeed {
                setLevelSpeed(intel.player.pointsPerSecond)
            } else {
                setLevelSpeed(150)
            }
            if self.audioEngine.mainMixerNode.outputVolume > 0.4 {
                setVolume(audioEngine.mainMixerNode.outputVolume-0.1)
            }
            self.perform(#selector(deceleratePlayer), with: nil, afterDelay: 0.01)
        }
    }
    
    // MARK: - SKPhysicsContactDelegate
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        switch collision {
        case MVAPhysicsCategory.car.rawValue | MVAPhysicsCategory.remover.rawValue:
            if let node = contact.bodyA.node as? MVACar {
                scrape(car: node)
            } else if let node = contact.bodyB.node as? MVACar {
                scrape(car: node)
            }
        case MVAPhysicsCategory.car.rawValue | MVAPhysicsCategory.car.rawValue:
            if let node1 = contact.bodyA.node as? MVACar,
                let node2 = contact.bodyB.node as? MVACar {
                let maxYFrame = self.camera!.position.y+self.size.height/2+MVAConstants.baseCarSize.height
                let minYFrame = self.camera!.position.y-self.size.height/2-MVAConstants.baseCarSize.height
                if maxYFrame > contact.contactPoint.y && contact.contactPoint.y > minYFrame {
                    for car in [node1,node2] {
                        car.pointsPerSecond = 0
                        car.removeAllActions()
                        car.removeAllChildren()
                        car.physicsBody!.isDynamic = false
                    }
                    sound.crash(onNode: node1)
                    generateSmoke(atPoint: contact.contactPoint, forTime: 25.0)
                } else {
                    for car in [node1,node2] {
                        scrape(car: car)
                    }
                }
            }
        case MVAPhysicsCategory.car.rawValue | MVAPhysicsCategory.player.rawValue:
            if intel.stop == false {
                physicsWorld.speed = 0.0
                intel.stop = true
                intel.player.pointsPerSecond = 0
                intel.player.removeAllActions()
                intel.player.removeAllChildren()
                intel.cars.forEach({
                    $0.removeAllActions()
                    $0.removeAllChildren()
                    $0.pointsPerSecond = 0
                })
                sound.crash(onNode: intel.player)
                generateSmoke(atPoint: contact.contactPoint, forTime: nil)
                hideHUD(animated: true)
                gameOver()
            }
        default: break
        }
    }
    
    private func generateSmoke(atPoint point: CGPoint, forTime time: TimeInterval?) {
        let particles = SKEmitterNode(fileNamed: "MVAParticle")
        particles?.position = point
        particles?.name = "smoke"
        particles?.zPosition = 5.5
        self.addChild(particles!)
        let remSmoke = SKAction.run {
            particles?.removeFromParent()
        }
        if time != nil {
            self.run(SKAction.sequence([SKAction.wait(forDuration: time!),remSmoke]))
        }
    }
    
    private func scrape(car: MVACar) {
        car.removeFromParent()
        car.pointsPerSecond = 0
        intel.cars.remove(car)
        spawner.usedCars.insert(car)
    }
}

