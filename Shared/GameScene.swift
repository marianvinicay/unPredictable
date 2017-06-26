//
//  GameScene.swift
//  (un)Predictable
//
//  Created by Majo on 25/08/16.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit
import UIKit

#if os(watchOS)
    import WatchKit
    // <rdar://problem/26756207> SKColor typealias does not seem to be exposed on watchOS SpriteKit
    typealias SKColor = UIColor
#endif

class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Variables
    // MARK: Gameplay Logic
    let intel = MVAMarvinAI()
    private var gameStarted = false
    
    // MARK: Buttons
    var playBtt: SKLabelNode!
    
    // MARK: Gameplay Sprites
    var cameraNode: SKCameraNode!
    private var roadNodes = [MVARoadNode]()
    private var remover: SKSpriteNode!
    private var spawner: MVACarSpawner!
    
    // MARK: Gameplay Helpers
    var lastPressedXPosition: CGFloat!
    private var endOfWorld: CGFloat = 0.0
    private var starterCount: UInt8 = 0
    private var brakingTimer: Timer!
    private var lastUpdate: TimeInterval = 0.0

    // MARK: - Init
    class func newGameScene(withSize deviceSize: CGSize) -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        //let scene = GameScene(size: size)
        guard let scene = GameScene(fileNamed: "GameScene") else {
            print("Failed to load GameScene.sks")
            abort()
        }
        scene.scaleMode = .aspectFill
        scene.isPaused = true
        scene.speed = 0
        scene.playBtt = scene.childNode(withName: "playBtt") as! SKLabelNode
        scene.initiateScene()
        return scene
    }
    
    func initiateScene() {
        let starterNode = self.childNode(withName: "starter") as! MVARoadNode
        roadNodes.append(starterNode)
        let road = MVARoadNode.createWith(numberOfLanes: 3, name: "Start2", height: starterNode.size.height, andWidth: starterNode.size.width)
        road.position.x = starterNode.position.x
        road.position.y = starterNode.size.height
        roadNodes.append(road)
        endOfWorld = road.position.y+road.size.height/2
        intel.lanePositions = road.laneXCoordinate
        self.addChild(road)
        
        cameraNode = SKCameraNode()
        cameraNode.position = starterNode.position
        self.camera = cameraNode
        self.addChild(cameraNode)
        
        spawner = MVACarSpawner.createSpawner(withWidth: frame.width)
        spawner.zPosition = 4.0
        spawner.position = CGPoint(x: 0.0, y: frame.height)
        self.addChild(spawner)
        
        //remover
        remover = SKSpriteNode(color: .purple, size: CGSize(width: frame.width, height: 10.0))
        remover.position = CGPoint(x: 0.0/*spawner.size.width/2*/, y: -frame.height)
        remover.zPosition = 4.0
        self.addChild(remover)
        remover.physicsBody = SKPhysicsBody(rectangleOf: remover.size)
        remover.physicsBody?.affectedByGravity = false
        remover.physicsBody?.isDynamic = false
        remover.physicsBody?.categoryBitMask = MVAPhysicsCategory.remover.rawValue
        remover.physicsBody?.collisionBitMask = MVAPhysicsCategory.remover.rawValue
        remover.physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue
        self.physicsWorld.contactDelegate = self
    }
    
    private func populateCars() {
        
    }
    
    /*#if os(watchOS)
    override func sceneDidLoad() {
        self.setUpScene()
    }
    #endif*/
    
    // MARK: - Gameplay
    func startGame() {
        if let pSprite = self.childNode(withName: "player") {
            gameStarted = true
            let player = MVACar(withSize: CGSize(), andMindSet: .player, img: "Audi")
            player.physicsBody?.categoryBitMask = MVAPhysicsCategory.player.rawValue
            player.physicsBody?.collisionBitMask = MVAPhysicsCategory.car.rawValue
            player.physicsBody?.collisionBitMask = MVAPhysicsCategory.car.rawValue
            player.physicsBody?.isDynamic = false
            let lane = 1    //Int(arc4random_uniform(road.numberOfLanes))
            player.position = pSprite.position  //CGPoint(x: road.laneXCoordinate[lane]!, y: size.height/3)
            player.currentLane = lane
            self.addChild(player)
            pSprite.removeFromParent()
            player.zPosition = 5.0
            player.changeSpeed(222)
            intel.player = player
        }
        
        let spawn = SKAction.run {
            self.spawner.spawn(withExistingCars: self.intel.cars, roadLanes: self.intel.lanePositions)
        }
        
        let wait = SKAction.wait(forDuration: 2.5)
        self.run(SKAction.repeatForever(SKAction.sequence([spawn,wait])), withKey: "spawn")
    }
    
    private func gameOver() {
        if intel.player.childNode(withName: "txt") == nil {
            let label = SKLabelNode(text: "Game\nOver!")
            label.name = "txt"
            label.fontSize += 10	
            intel.player.addChild(label)
            label.position.y += size.height/4
            self.isPaused = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { [unowned label] in
                self.isPaused = false
                self.intel.player.removeChildren(in: [label])
            })
        }
    }
    
    func handleSwipe(swipe: MVAPosition) {
        if gameStarted {
            guard intel.player.mindSet == .player else { return }
            _ = intel.player.changeLane(inDirection: swipe, withLanePositions: intel.lanePositions, AndPlayer: intel.player)
        }
    }
    
    func handleBrake(started: Bool) {
        if gameStarted {
            guard intel.player.mindSet == .player else { return }
            if started {
                brakingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (_: Timer) in
                    if let act = self.intel.player.action(forKey: "move") {
                        if act.speed > 0.2 {
                            self.intel.player.pointsPerSecond *= 0.85
                            act.speed -= 0.2
                        }
                    }
                })
            } else {
                brakingTimer.invalidate()
                brakingTimer = nil
                if let act = intel.player.action(forKey: "move") {
                    while act.speed < 1.0 {
                        act.speed += 0.2
                    }
                    act.speed = 1.0
                    intel.player.pointsPerSecond = 250
                }
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        updateCamera()
        if gameStarted {
            //if currentTime-lastUpdate < 10 {//??? firstLoad run time
            intel.update(withDeltaTime: currentTime-lastUpdate)
            //}
            lastUpdate = currentTime
            
            if endOfWorld-50<self.cameraNode.position.y+self.size.height/2 {
                let spriteName = starterCount < 2 ? "Start2":"road"
                starterCount += 1
                let example = roadNodes.last!
                let road = MVARoadNode.createWith(numberOfLanes: 3, name: spriteName, height: example.size.height, andWidth: example.size.width)
                road.position.x = example.position.x //self.size.width/2
                road.position.y = example.position.y+road.size.height //endOfWorld+road.size.height/2
                self.addChild(road)
                roadNodes.append(road)
                endOfWorld += road.size.height
            }
            
            //then try enumerate nodes with name road
            for road in roadNodes {
                let roadPosition = road.position.y+road.size.height
                if roadPosition < (self.cameraNode.position.y-self.size.height/2)-10 {
                    road.removeFromParent()
                    if let i = roadNodes.index(of: road) {
                        roadNodes.remove(at: i)
                    }
                }
            }
        }
    }
    
    private func updateCamera() {
        spawner.position.y = cameraNode.position.y+self.size.height
        if intel.player != nil {
            let desiredCameraPosition = intel.player.position.y+size.height/4
            cameraNode.run(SKAction.moveTo(y: desiredCameraPosition, duration: 0.2))
        }
        remover.position.y = cameraNode.position.y-self.size.height
    }
    
    // MARK: - SKPhysicsContactDelegate
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask & contact.bodyB.categoryBitMask
        if collision == MVAPhysicsCategory.car.rawValue & MVAPhysicsCategory.remover.rawValue {
            if contact.bodyA.categoryBitMask == MVAPhysicsCategory.car.rawValue {
                if let node = contact.bodyA.node as? MVACar {
                    node.removeFromParent()
                    intel.cars.remove(node)
                }
            } else {
                if let node = contact.bodyB.node as? MVACar {
                    node.removeFromParent()
                    intel.cars.remove(node)
                }
            }
        } else if collision == MVAPhysicsCategory.car.rawValue & MVAPhysicsCategory.player.rawValue {
            gameOver()
        }
    }
}

#if os(OSX)
// Mouse-based event handling
extension GameScene {

    override func mouseDown(with event: NSEvent) {
    }
    
    override func mouseDragged(with event: NSEvent) {
    }
    
    override func mouseUp(with event: NSEvent) {
    }

}
#endif

