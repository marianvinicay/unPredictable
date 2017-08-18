//
//  GameScene.swift
//  (un)Predictable
//
//  Created by Majo on 25/08/16.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit

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
    var lives: SKSpriteNode!
    var battery: SKSpriteNode!
    var roadNodes = Set<MVARoadNode>()
    var remover: MVARemoverNode!
    var spawner: MVASpawnerNode!
    
    // MARK: Gameplay Helpers
    var tutorialNode: MVATutorialNode?
    var batteryTime = 0.0
    var lastPressedXPosition: CGFloat!
    var endOfWorld: CGFloat? = 0.0
    var brakingTimer: Timer!
    var lastUpdate: TimeInterval!
    let sound = MVASound()
    var newBestDisplayed = false
    var canUpdateSpeed = true
    
    // MARK: - Gameplay
    func spawnWithDelay(_ delay: TimeInterval) {
        self.removeAction(forKey: "spawn")
        let spawn = SKAction.run {
            self.spawner.spawnCar(withExistingCars: self.intel.cars.filter({ $0.position.y > self.camera!.position.y+self.size.height/3 }))
        }
        let wait = SKAction.wait(forDuration: delay)
        self.run(SKAction.repeatForever(SKAction.sequence([spawn,wait])), withKey: "spawn")
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
    
    private func updateCamera() {
        spawner.position.y = camera!.position.y+self.size.height
        if intel.player != nil {
            let desiredCameraPosition = intel.player.position.y+size.height/4
            camera!.run(SKAction.moveTo(y: desiredCameraPosition, duration: 0.02))
            //camera!.position.y = desiredCameraPosition
        }
        remover.position.y = camera!.position.y-self.size.height
    }
    
    override func update(_ currentTime: TimeInterval) {
        updateCamera()
        if gameStarted {
            if lastUpdate != nil {
                let dTime = currentTime-lastUpdate
                intel.update(withDeltaTime: dTime)
                
                if intel.player.pcsActive && !playerBraking {
                    if intel.checkPCS(withDeltaTime: dTime) {
                        removeLife()
                    }
                }
                
                if batteryTime > 0 {
                    batteryTime -= dTime
                }
            }
            lastUpdate = currentTime

            DispatchQueue.main.async {
                if self.batteryTime <= 0 && self.intel.playerLives < 3 {
                    self.addToBattery()
                }
                
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
    
    private func endTutorial() {
        tutorialNode?.end {
            self.tutorialNode?.removeFromParent()
            self.tutorialNode = nil
            self.intel.updateDist = true
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
            if intel.player.changeLane(inDirection: swipe) {
                sound.indicate(onNode: intel.player)
                
                if tutorialNode?.stage == 0 {
                    spawnWithDelay(intel.currentLevel.spawnRate)
                    tutorialNode!.continueToBraking()
                }
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
                    intel.player.brakeLight(true)
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
    
    func handleBrakingSwipe(fromPositionChange posCh: CGFloat) {
        if gameStarted && physicsWorld.speed != 0.0 {
            guard tutorialNode == nil || tutorialNode?.stage != 0 else { return }
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
        if playerBraking {
            var minSpeed = 150
            if let carInFront = intel.player.responseFromSensors(inPositions: [.front, .stop]).first {
                if carInFront.pointsPerSecond > 1 && carInFront.pointsPerSecond < 111 {
                    minSpeed = carInFront.pointsPerSecond
                }
            }

            if intel.player.pointsPerSecond > minSpeed {
                let backForce = intel.currentLevel.level > 6 ? CGFloat((intel.currentLevel.playerSpeed/5)*13)*1.8 : CGFloat((intel.currentLevel.playerSpeed/5)*13)
                intel.player.physicsBody!.applyForce(CGVector(dx: 0.0, dy: -intel.player.physicsBody!.mass*backForce))

                setLevelSpeed(intel.player.pointsPerSecond)
                
                if self.audioEngine.mainMixerNode.outputVolume > 0.4 {
                    setVolume(audioEngine.mainMixerNode.outputVolume-0.1)
                }
            } else {
                setLevelSpeed(150)
            }
            self.perform(#selector(deceleratePlayer), with: nil, afterDelay: 0.01)
        }
    }
    
    // MARK: - SKPhysicsContactDelegate
    private var playerInCollision = false
    
    func cancelPlayerCollision() { playerInCollision = false }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        switch collision {
        case MVAPhysicsCategory.car.rawValue | MVAPhysicsCategory.remover.rawValue:
            if let node = contact.bodyA.node as? MVACarBot {
                scrape(car: node)
            } else if let node = contact.bodyB.node as? MVACarBot {
                scrape(car: node)
            }
        case MVAPhysicsCategory.car.rawValue | MVAPhysicsCategory.car.rawValue:
            if let node1 = contact.bodyA.node as? MVACarBot,
                let node2 = contact.bodyB.node as? MVACarBot {
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
            if !playerInCollision {
                playerInCollision = true
                if intel.player.skin.name == MVACarNames.playerLives && intel.playerLives > 0 {
                    removeLife()
                    sound.crash(onNode: intel.player)
                    let ordCar = [contact.bodyA.node, contact.bodyB.node].map({ $0 as? MVACarBot })
                    for car in ordCar {
                        if car != nil { scrape(car: car!) }
                    }
                    intel.player.resetPhysicsBody()
                    intel.player.pointsPerSecond = intel.currentLevel.playerSpeed
                } else {
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
                    self.camera!.childNode(withName: "nBest")?.removeFromParent()
                    gameOver()
                }
                perform(#selector(cancelPlayerCollision), with: nil, afterDelay: 0.05)
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
    
    private func scrape(car: MVACarBot) {
        car.removeFromParent()
        car.pointsPerSecond = 0
        intel.cars.remove(car)
        spawner.usedCars.insert(car)
    }
}

