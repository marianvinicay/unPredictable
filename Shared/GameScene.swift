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
    
    // MARK: Buttons
    var playBtt: SKSpriteNode!
    var pauseBtt: SKSpriteNode!
    var originalPausePosition: CGPoint!
    
    // MARK: Gameplay Sprites
    var speedSign: HUDLabel!
    var originalSpeedPosition: CGPoint!
    var distanceSign: HUDLabel!
    var originalDistancePosition: CGPoint!
    private var roadNodes = Set<MVARoadNode>()
    private var remover: SKSpriteNode!
    private var spawner: MVASpawner!
    
    // MARK: Gameplay Helpers
    var lastPressedXPosition: CGFloat!
    private var endOfWorld: CGFloat? = 0.0
    private var brakingTimer: Timer!
    private var lastUpdate: TimeInterval!

    // MARK: - Init
    class func newGameScene(withSize deviceSize: CGSize) -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        var gameSceneName = "GameScene"
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            gameSceneName = "GameSceneiPad"
        }
        #endif
        guard let scene = GameScene(fileNamed: gameSceneName) else {
            print("Failed to load GameScene.sks")
            abort()
        }
        scene.scaleMode = .aspectFill
        scene.size = deviceSize
        scene.isPaused = true
        scene.playBtt = scene.camera!.childNode(withName: "playBtt") as! SKSpriteNode
        scene.pauseBtt = scene.camera!.childNode(withName: "stop") as! SKSpriteNode
        scene.originalPausePosition = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
        scene.pauseBtt.position = scene.originalPausePosition
        
        scene.speedSign = scene.camera!.childNode(withName: "speed") as! HUDLabel
        scene.originalSpeedPosition = CGPoint(x: -(scene.size.width/2)+scene.speedSign.size.width/2, y: (scene.size.height/2)-scene.speedSign.size.height/2)
        scene.speedSign.position = scene.originalSpeedPosition
        scene.camera!.childNode(withName: "spdB")!.position = scene.originalSpeedPosition
        
        scene.distanceSign = scene.camera!.childNode(withName: "distance") as! HUDLabel
        scene.originalDistancePosition = CGPoint(x: -scene.size.width/2, y: -scene.size.height/2)
        scene.distanceSign.position = scene.originalDistancePosition
        scene.camera!.childNode(withName: "down")!.position = CGPoint(x: 0.0, y: -scene.size.height/2)
        
        scene.setLevelSpeed(0)
        scene.setDistance(MVAWorldConverter.distanceToOdometer(0.0))
        
        scene.hideHUD(animated: false)
        scene.initiateScene()
        return scene
    }
    
    private func spawnPlayer() {
        let pSkin = MVASkin.createForCar("audi", withAtlas: spawner.textures)
        let player = MVACar(withMindSet: .player, andSkin: pSkin)
        player.physicsBody?.categoryBitMask = MVAPhysicsCategory.player.rawValue
        player.physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue
        player.physicsBody?.collisionBitMask = MVAPhysicsCategory.car.rawValue
        player.physicsBody?.isDynamic = true
        player.position = CGPoint(x: 0.0, y: -self.size.height/13)
        self.addChild(player)
        player.zPosition = 5.0
        intel.player = player
    }
    
    private func spawnStartRoad() {
        if let starterNode = self.childNode(withName: "starter") as? MVARoadNode {
            starterNode.size = self.size
            starterNode.position = .zero
            roadNodes.insert(starterNode)
            endOfWorld = starterNode.position.y+starterNode.size.height
        } else {
            let starterNode = MVARoadNode.createWith(numberOfLanes: 3, texture: SKTexture(imageNamed: "Start1"), height: self.size.height, andWidth: self.size.width)
            starterNode.position = .zero
            self.addChild(starterNode)
            roadNodes.insert(starterNode)
            endOfWorld = starterNode.position.y+starterNode.size.height
        }
        
        let start2Texture = SKTexture(imageNamed: "Start2")
        for _ in 0..<3 {
            let road = MVARoadNode.createWith(numberOfLanes: 3, texture: start2Texture, height: self.size.height, andWidth: self.size.width)
            switch arc4random_uniform(2) {
            case 1:
                let pSpot = arc4random_uniform(2) == 0 ? SKSpriteNode(imageNamed: "ParkingSpotR"):SKSpriteNode(imageNamed: "ParkingSpotL")
                pSpot.size = pSpot.size.adjustSize(toNewWidth: road.size.width)
                pSpot.position = CGPoint(x: 0.0, y: CGFloat(arc4random_uniform(UInt32(road.size.height-pSpot.size.height)))+pSpot.size.height/2)
                pSpot.zPosition = 1.0
                road.addChild(pSpot)
            default: break
            }
            road.position.x = 0.0
            road.position.y = endOfWorld!
            endOfWorld = road.position.y+road.size.height
            self.addChild(road)
        }
        
        let road = MVARoadNode.createWith(numberOfLanes: 3, texture: spawner.roadTexture, height: self.size.height*1.5, andWidth: self.size.width)
        road.position.x = 0.0
        road.position.y = endOfWorld!+self.size.height*0.25
        self.addChild(road)
        
        intel.lanePositions = road.laneXCoordinate
    }
    
    func initiateScene() {
        spawner = MVASpawner.createCarSpawner(withSize: CGSize(width: size.width, height: MVAConstants.baseCarSize.height*2.5))
        spawner.zPosition = 4.0
        spawner.position = CGPoint(x: 0.0, y: self.frame.height*1.5)
        self.addChild(spawner)
        
        spawnPlayer()
        setLevelSpeed(0)
        spawnStartRoad()
                
        //remover
        remover = SKSpriteNode(color: .clear, size: CGSize(width: size.width, height: 5.0))
        remover.position = CGPoint(x: 0.0, y: -frame.height)
        remover.zPosition = 4.0
        self.addChild(remover)
        
        remover.physicsBody = SKPhysicsBody(rectangleOf: remover.size)
        remover.physicsBody?.affectedByGravity = false
        remover.physicsBody?.isDynamic = false
        remover.physicsBody?.collisionBitMask = MVAPhysicsCategory.remover.rawValue
        
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.speed = 1.0
    }
    
    private func resetScene() {
        self.playBtt.setScale(1.0)
        
        lastUpdate = nil
        gameStarted = false
        playerDistance = "0.0"
        playerBraking = false
        playerAccelerating = false
        roadNodes.removeAll()
        
        setLevelSpeed(0)
        setDistance(MVAWorldConverter.distanceToOdometer(0.0))
        
        intel.reset()
        spawnPlayer()
        
        endOfWorld = 0.0
        spawnStartRoad()
        
        camera!.childNode(withName: "Road")?.removeFromParent()
        camera!.position = .zero
        
        spawner.usedCars.removeAll()
        spawner.size.height = MVAConstants.baseCarSize.height*2.5
        remover.position = CGPoint(x: 0.0, y: -frame.height)
    }
    
    // MARK: - Gameplay
    func startGame() {
        self.isPaused = false
        self.physicsWorld.speed = 0.0
        let targetY = (self.size.height/2)-MVAConstants.baseCarSize.height
        let randLane = Int(arc4random_uniform(3))
        let randLanePos = CGFloat(intel.lanePositions[randLane]!)
        let whereToGo = CGPoint(x: randLanePos, y: targetY)
        let angle = atan2(intel.player.position.y - whereToGo.y, intel.player.position.x - whereToGo.x)+CGFloat(Double.pi*0.5)
        
        let moveOut = SKAction.moveTo(y: 80, duration: 1.0)
        let turnIn = SKAction.sequence([SKAction.wait(forDuration: 0.85),SKAction.rotate(toAngle: angle, duration: 0.3)])
        let moveIn = SKAction.sequence([SKAction.wait(forDuration: 1.0),SKAction.move(to: CGPoint(x: randLanePos, y: targetY), duration: 1.0)])
        let turnOut = SKAction.sequence([SKAction.wait(forDuration: 1.85),SKAction.rotate(toAngle: 0, duration: 0.3)])
        intel.player.currentLane = randLane
        intel.player.run(SKAction.group([moveOut,turnIn,moveIn,turnOut]))
        let curtainUp = SKAction.run {
            self.showHUD()
            self.camera!.childNode(withName: "over")?.run(SKAction.fadeOut(withDuration: 1.0))
        }
        let start = SKAction.run {
            self.physicsWorld.speed = 1.0
            self.isUserInteractionEnabled = true
            self.intel.player.pointsPerSecond = self.intel.currentLevel.playerSpeed
            self.setLevelSpeed(self.intel.currentLevel.playerSpeed)
            self.spawnWithDelay(self.intel.currentLevel.spawnRate)
            self.gameStarted = true
        }
        playBtt.run(SKAction.sequence([SKAction.group([SKAction.scale(to: 0.0, duration: 1.0),curtainUp]),SKAction.wait(forDuration: 1.1),start]))
    }
    
    private func gameOver() {
        if intel.player.childNode(withName: "txt") == nil {
            let label = SKLabelNode(text: "Game\nOver!")
            label.fontName = "Futura Bold"
            label.fontSize = 40
            label.position = .zero
            label.zPosition = 6.0
            camera!.addChild(label)
            let resetAction = SKAction.run {
                label.removeFromParent()
                self.resetScene()
            }
            let curtainDown = SKAction.run {
                self.camera!.childNode(withName: "over")?.run(SKAction.fadeIn(withDuration: 0.5))
            }
            self.run(SKAction.sequence([SKAction.group([SKAction.wait(forDuration: 1.0),curtainDown]),resetAction]))
        }
    }
    
    private func nextLevelSign() {
        self.removeAction(forKey: "spawn")
        self.physicsWorld.speed = 0.0
        let rightScale = speedSign.xScale
        let signIN = SKAction.group([SKAction.scale(to: 0.3, duration: 0.4),SKAction.move(to: CGPoint.zero, duration: 0.4)])
        let signOUT = SKAction.group([SKAction.scale(to: rightScale, duration: 0.3),SKAction.move(to: originalSpeedPosition, duration: 0.3)])
        speedSign.run(SKAction.sequence([signIN,SKAction.wait(forDuration: 0.6),signOUT]), completion: {
            self.physicsWorld.speed = 1.0
            self.spawnWithDelay(self.intel.currentLevel.spawnRate)
        })
    }
    
    func handleSwipe(swipe: MVAPosition) {
        if gameStarted && physicsWorld.speed != 0.0 {
            guard intel.player.mindSet == .player else { return }
            _ = intel.player.changeLane(inDirection: swipe, withLanePositions: intel.lanePositions, AndPlayer: intel.player)
        }
    }
    
    var playerBraking = false
    var playerAccelerating = false
    
    func handleBrake(started: Bool) {
        if gameStarted && physicsWorld.speed != 0.0 {
            if started {
                if playerBraking == false {
                    self.removeAction(forKey: "spawn")
                    spawner.size.height = self.size.height
                    playerBraking = true
                }
                if intel.player.pointsPerSecond > intel.currentLevel.playerSpeed/4 {
                    intel.player.physicsBody!.applyForce(CGVector(dx: 0.0, dy: -intel.player.physicsBody!.mass*550))
                    intel.player.brakeLight(true)
                    if intel.player.pointsPerSecond*2 > intel.currentLevel.playerSpeed/5 {
                        setLevelSpeed(intel.player.pointsPerSecond)
                    } else {
                        setLevelSpeed(intel.player.pointsPerSecond*2)
                    }
                }
            } else {
                if playerBraking == true {
                    spawnWithDelay(intel.currentLevel.spawnRate)
                    playerBraking = false
                    playerAccelerating = true
                    intel.player.brakeLight(false)
                }
                
                if intel.player.pointsPerSecond < intel.currentLevel.playerSpeed {
                    intel.player.physicsBody!.applyForce(CGVector(dx: 0.0, dy: intel.player.physicsBody!.mass*500))
                    if intel.player.pointsPerSecond*2 > intel.currentLevel.playerSpeed/5 {
                        setLevelSpeed(intel.player.pointsPerSecond)
                    } else {
                        setLevelSpeed(intel.player.pointsPerSecond*2)
                    }
                } else {
                    intel.player.pointsPerSecond = intel.currentLevel.playerSpeed
                    playerAccelerating = false
                    setLevelSpeed(intel.currentLevel.playerSpeed)
                    spawner.size.height = MVAConstants.baseCarSize.height*2.5
                }
            }
        }
    }
    
    // TODO: improve
    override func update(_ currentTime: TimeInterval) {
        updateCamera()
        if gameStarted {
            if lastUpdate == nil {
                lastUpdate = currentTime
            } else {
                intel.update(withDeltaTime: currentTime-lastUpdate)
                lastUpdate = currentTime
            }
            
            if playerBraking {
                handleBrake(started: true)
            } else if playerAccelerating {
                handleBrake(started: false)
            }
            
            DispatchQueue.main.async {
                if self.intel.distanceTraveled > Double(self.intel.currentLevel.nextMilestone) && !self.playerBraking {
                    self.intel.currentLevel.level += 1
                    self.spawnWithDelay(self.intel.currentLevel.spawnRate)
                    self.intel.player.changeSpeed(self.intel.currentLevel.playerSpeed)
                    self.setLevelSpeed(self.intel.currentLevel.playerSpeed)
                    self.nextLevelSign()
                }
                let newDistance = MVAWorldConverter.distanceToOdometer(self.intel.distanceTraveled)
                if self.playerDistance != newDistance {
                    self.playerDistance = newDistance
                    self.setDistance(newDistance)
                }
            }
            
            if endOfWorld != nil && endOfWorld! < self.camera!.position.y {
                let road = MVARoadNode.createWith(numberOfLanes: 3, texture: spawner.roadTexture, height: self.size.height, andWidth: self.size.width)
                road.position = .zero
                road.name = "Road"
                camera!.addChild(road)
                endOfWorld = nil
                roadNodes.forEach({ $0.removeFromParent() })
                roadNodes.removeAll()
            }
        }
    }
    
    private func spawnWithDelay(_ delay: TimeInterval) {
        self.removeAction(forKey: "spawn")
        let spawn = SKAction.run {
            for newCar in self.spawner.spawnCar(withExistingCars: self.intel.cars.filter({ $0.position.y > self.camera!.position.y+self.size.height/2 }), roadLanes: self.intel.lanePositions) {
                self.addChild(newCar)
                self.intel.cars.insert(newCar)
            }
        }
        let wait = SKAction.wait(forDuration: delay)
        self.run(SKAction.repeatForever(SKAction.sequence([spawn,wait])), withKey: "spawn")
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
    
    // MARK: - SKPhysicsContactDelegate
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask & contact.bodyB.categoryBitMask
        let removeCol = MVAPhysicsCategory.car.rawValue & MVAPhysicsCategory.remover.rawValue
        let carCol = MVAPhysicsCategory.car.rawValue & MVAPhysicsCategory.car.rawValue
        let playerCol = MVAPhysicsCategory.car.rawValue & MVAPhysicsCategory.player.rawValue
        
        switch collision {
        case removeCol:
            if let node = contact.bodyA.node as? MVACar {
                scrape(car: node)
            } else if let node = contact.bodyB.node as? MVACar {
                scrape(car: node)
            }
        case carCol:
            if let node1 = contact.bodyA.node as? MVACar,
                let node2 = contact.bodyB.node as? MVACar {
                node1.pointsPerSecond = 0
                node2.pointsPerSecond = 0
            }
        case playerCol:
            hideHUD(animated: true)
            gameOver()
        default: break
        }
    }
    
    private func scrape(car: MVACar) {
        car.removeFromParent()
        car.pointsPerSecond = 0
        intel.cars.remove(car)
        spawner.usedCars.append(car)
    }
}

