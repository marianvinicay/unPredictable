//
//  GameScene.swift
//  (un)Predictable
//
//  Created by Majo on 25/08/16.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit
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
    let gameCHelper = MVAGameCenterHelper()
    
    // MARK: Buttons
    var playBtt: SKSpriteNode!
    var pauseBtt: SKSpriteNode!
    var originalPausePosition: CGPoint!
    
    // MARK: Gameplay Sprites
    var speedSign: HUDLabel!
    var originalSpeedPosition: CGPoint!
    var distanceSign: HUDLabel!
    var originalDistancePosition: CGPoint!
    var recordDistance: SKLabelNode!
    var roadNodes = Set<MVARoadNode>()
    var remover: SKSpriteNode!
    var spawner: MVASpawner!
    
    // MARK: Gameplay Helpers
    var lastPressedXPosition: CGFloat!
    var endOfWorld: CGFloat? = 0.0
    var brakingTimer: Timer!
    var lastUpdate: TimeInterval!
    let sound = MVASound()
    var newBestDisplayed = false
    
    // MARK: - Gameplay
    func startGame() {
        self.physicsWorld.speed = 1.0
        let targetY = (self.size.height/2)-MVAConstants.baseCarSize.height
        let randLane = Int(arc4random_uniform(3))
        let randLanePos = CGFloat(lanePositions[randLane]!)
        let whereToGo = CGPoint(x: randLanePos, y: targetY)
        let angle = atan2(intel.player.position.y - whereToGo.y, intel.player.position.x - whereToGo.x)+CGFloat(Double.pi*0.5)
        
        NotificationCenter.default.post(name: MVAGameCenterHelper.toggleGCBtt, object: nil)
        startSound()
        intel.player.pointsPerSecond = intel.currentLevel.playerSpeed
        let turnIn = SKAction.sequence([SKAction.wait(forDuration: 0.6),SKAction.rotate(toAngle: angle, duration: 0.2)])
        let moveIn = SKAction.sequence([SKAction.wait(forDuration: 0.7),SKAction.moveTo(x: randLanePos, duration: 0.7)])
        let turnOut = SKAction.sequence([SKAction.wait(forDuration: 1.3),SKAction.rotate(toAngle: 0, duration: 0.2)])
        intel.player.currentLane = randLane
        intel.player.run(SKAction.group([turnIn,moveIn,turnOut]))
        let curtainUp = SKAction.run {
            self.showHUD()
            self.recordDistance.run(SKAction.scale(to: 0.0, duration: 0.9))
            self.camera!.childNode(withName: "over")?.run(SKAction.fadeOut(withDuration: 1.0))
        }
        let start = SKAction.run {
            self.intel.player.pointsPerSecond = self.intel.currentLevel.playerSpeed
            self.setLevelSpeed(self.intel.currentLevel.playerSpeed)
            self.spawnWithDelay(self.intel.currentLevel.spawnRate)
            self.gameStarted = true
            self.physicsWorld.speed = 1.0
            self.isUserInteractionEnabled = true
        }
        playBtt.run(SKAction.sequence([SKAction.group([SKAction.scale(to: 0.0, duration: 1.0),curtainUp]),SKAction.wait(forDuration: 0.4),start]))
    }
    
    private func gameOver() {
        if intel.player.childNode(withName: "txt") == nil {
            let label = SKLabelNode(text: "Game Over!")
            label.fontName = "Futura Bold"
            label.fontSize = 40
            label.position = .zero
            label.zPosition = 6.0
            camera!.addChild(label)
            fadeOutVolume()
            
            let resetAction = SKAction.run {
                label.removeFromParent()
                self.resetScene()
            }
            let curtainDown = SKAction.run {
                self.removeAction(forKey: "spawn")
                self.camera!.childNode(withName: "over")?.run(SKAction.fadeIn(withDuration: 0.5))
            }
            
            self.run(SKAction.sequence([SKAction.group([SKAction.wait(forDuration: 1.5),curtainDown]),resetAction]))
        }
    }
    
    private func nextLevelSign() {
        self.removeAction(forKey: "spawn")
        self.physicsWorld.speed = 0.0
        let rightScale = speedSign.xScale
        let signIN = SKAction.group([SKAction.scale(to: 0.3, duration: 0.4),SKAction.move(to: CGPoint.zero, duration: 0.4)])
        let signOUT = SKAction.group([SKAction.scale(to: rightScale, duration: 0.3),SKAction.move(to: originalSpeedPosition, duration: 0.3)])
        speedSign.run(SKAction.sequence([signIN,SKAction.wait(forDuration: 0.8),signOUT]), completion: {
            self.physicsWorld.speed = 1.0
            self.spawnWithDelay(self.intel.currentLevel.spawnRate)
        })
    }
    
    private func displayNewBest() {
        newBestDisplayed = true
        let label = SKLabelNode(fontNamed: "Futura Bold")
        label.fontSize = 20
        label.text = "New Best!"
        label.verticalAlignmentMode = .bottom
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: distanceSign.position.x+distanceSign.size.width+10, y: (-self.size.height/2)+label.frame.height)//???
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
            if lastUpdate == nil {
                lastUpdate = currentTime
            } else {
                intel.update(withDeltaTime: currentTime-lastUpdate)
                lastUpdate = currentTime
            }
            
            DispatchQueue.main.async {
                if self.intel.distanceTraveled >= Double(self.intel.currentLevel.nextMilestone) && !self.playerBraking {
                    self.intel.currentLevel.level += 1
                    self.spawnWithDelay(self.intel.currentLevel.spawnRate)
                    self.intel.player.changeSpeed(self.intel.currentLevel.playerSpeed)
                    self.setLevelSpeed(self.intel.currentLevel.playerSpeed)
                    self.nextLevelSign()
                }
                let newDistance = MVAWorldConverter.distanceToOdometer(self.intel.distanceTraveled)
                if self.playerDistance != newDistance {
                    if !self.newBestDisplayed && MVAMemory.maxPlayerDistance != nil && (MVAMemory.maxPlayerDistance! <= self.intel.distanceTraveled) {
                        self.displayNewBest()
                    }
                    self.playerDistance = newDistance
                    self.setDistance(newDistance)
                }
            }
            
            if endOfWorld != nil && endOfWorld! < self.camera!.position.y {
                let road = MVARoadNode.createWith(texture: spawner.roadTexture, height: self.size.height, andWidth: self.size.width)
                road.position = .zero
                road.name = "road"
                camera!.addChild(road)
                endOfWorld = nil
                roadNodes.forEach({
                    $0.removeFromParent()
                    roadNodes.remove($0)
                })
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
    
    
    // MARK: - Controls
    func handleSwipe(swipe: MVAPosition) {
        if gameStarted && physicsWorld.speed != 0.0 {
            guard intel.player.mindSet == .player else { return }
            sound.indicate(onNode: intel.player)
            _ = intel.player.changeLane(inDirection: swipe, AndPlayer: intel.player)
        }
    }
    
    func handleBrake(started: Bool) {
        if gameStarted {
            if started {
                if playerBraking == false {
                    self.removeAction(forKey: "spawn")
                    spawner.size.height = self.size.height
                    playerBraking = true
                }
                generateSmoke(atPoint: intel.player.position)
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
        if intel.player.pointsPerSecond < intel.currentLevel.playerSpeed {
            intel.player.physicsBody!.applyForce(CGVector(dx: 0.0, dy: intel.player.physicsBody!.mass*500))
            if intel.player.pointsPerSecond > 150 {
                setLevelSpeed(intel.player.pointsPerSecond)
            }
            if self.audioEngine.mainMixerNode.outputVolume < 1.0 {
                self.audioEngine.mainMixerNode.outputVolume += 0.1
            }
            self.perform(#selector(acceleratePlayer), with: nil, afterDelay: 0.01)
        } else {
            intel.player.pointsPerSecond = intel.currentLevel.playerSpeed
            setLevelSpeed(intel.currentLevel.playerSpeed)
            spawner.size.height = MVAConstants.baseCarSize.height*2.5
            self.audioEngine.mainMixerNode.outputVolume = 1.0
        }
    }
    
    func deceleratePlayer() {
        if playerBraking && intel.player.pointsPerSecond > MVAConstants.minimalBotSpeed-15 {
            intel.player.physicsBody!.applyForce(CGVector(dx: 0.0, dy: -intel.player.physicsBody!.mass*600))
            intel.player.brakeLight(true)
            if intel.player.pointsPerSecond > 150 {
                setLevelSpeed(intel.player.pointsPerSecond)
            } else {
                setLevelSpeed(150)
            }
            if self.audioEngine.mainMixerNode.outputVolume > 0.4 {
                self.audioEngine.mainMixerNode.outputVolume -= 0.1
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
                    generateSmoke(atPoint: contact.contactPoint)
                } else {
                    for car in [node1,node2] {
                        scrape(car: car)
                    }
                }
            }
        case MVAPhysicsCategory.car.rawValue | MVAPhysicsCategory.player.rawValue:
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
            generateSmoke(atPoint: contact.contactPoint)
            hideHUD(animated: true)
            gameOver()
        default: break
        }
    }
    
    private func generateSmoke(atPoint point: CGPoint) {
        let particles = SKEmitterNode(fileNamed: "MVAParticle")
        particles?.position = point
        particles?.name = "smoke"
        particles?.zPosition = 4.0
        self.addChild(particles!)
        let remSmoke = SKAction.run {
            particles?.removeFromParent()
        }
        self.run(SKAction.sequence([SKAction.wait(forDuration: 6.0),remSmoke]))
    }
    
    private func scrape(car: MVACar) {
        car.removeFromParent()
        car.pointsPerSecond = 0
        intel.cars.remove(car)
        spawner.usedCars.insert(car)
    }
}

