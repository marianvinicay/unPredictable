//
//  GameSceneWatch.swift
//  unPredictable
//
//  Created by Majo on 20/08/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

class GameSceneWatch: SKScene {
    // MARK: - Variables
    // MARK: Gameplay Logic
    //let intel = MVAMarvinAI()
    var playerDistance = "0.0"
    var gameStarted = false
    var playerBraking = false
    var timesCrashed = 0
    
    // MARK: Gameplay Sprites
    var speedSign: SKSpriteNode!
    var originalSpeedPosition: CGPoint!
    var distanceSign: SKSpriteNode!
    var originalDistancePosition: CGPoint!
    //var roadNodes = Set<MVARoadNode>()
    var remover: MVARemoverNode!
    //var spawner: MVASpawnerNode!
    
    // MARK: Gameplay Helpers
    //var tutorialNode: MVATutorialNode?
    var endOfWorld: CGFloat? = 0.0
    var brakingTimer: Timer!
    var lastUpdate: TimeInterval!
    var newBestDisplayed = false
    var canUpdateSpeed = true
    
    class func newScene() -> GameSceneWatch {
        guard let scene = GameSceneWatch(fileNamed: "GameSceneWatch") else { abort() }
        
        scene.scaleMode = .aspectFill
        scene.camera = (scene.childNode(withName: "cam") as! SKCameraNode)
        
        scene.speedSign = scene.camera!.childNode(withName: "speed") as! SKSpriteNode
        scene.originalSpeedPosition = CGPoint(x: -(scene.size.width/2)+scene.speedSign.size.width/2, y: (scene.size.height/2)-scene.speedSign.size.height/2)
        scene.speedSign.position = scene.originalSpeedPosition
        
        scene.distanceSign = scene.camera!.childNode(withName: "distance") as! SKSpriteNode
        scene.originalDistancePosition = CGPoint(x: -scene.size.width/2, y: -scene.size.height/2)
        scene.distanceSign.position = scene.originalDistancePosition
        
        //scene.setLevelSpeed(50)
        //scene.setDistance(MVAWorldConverter.distanceToOdometer(2.0))
        
        //scene.hideHUD(animated: false)
        scene.initiateScene()
        
        return scene
    }
    
    func initiateScene() {
        /*spawner = MVASpawnerNode.createCarSpawner(withSize: CGSize(width: size.width, height: MVAConstants.baseCarSize.height*2.5))
        spawner.position = CGPoint(x: 0.0, y: self.frame.height*1.5)
        spawner.zPosition = 4.0
        spawner.name = "spawner"
        self.addChild(spawner)
        
        spawnPlayer()
        setLevelSpeed(0)
        spawnStartRoad()*/
        spawnPlayer()
        
        //remover
        remover = MVARemoverNode.createRemover(withSize: CGSize(width: size.width, height: 36))//CAR HEIGHT
        remover.position = CGPoint(x: 0.0, y: -frame.height)
        remover.zPosition = 4.0
        remover.name = "remover"
        self.addChild(remover)
        
        //self.audioEngine.prepare()
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.speed = 0.0
        
        //intel.sound.ignite(node: self)
    }
    
    func spawnPlayer() {
        /*let textu = SKTextureAtlas(named: "Cars")
        let pSkin = MVASkin.createForCar(MVAMemory.playerCar, withAtlas: textu)
        let player = MVACarPlayer.new(withSkin: pSkin)
        player.physicsBody?.categoryBitMask = MVAPhysicsCategory.player.rawValue
        player.physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue
        player.physicsBody?.collisionBitMask = MVAPhysicsCategory.car.rawValue
        player.physicsBody?.isDynamic = true
        player.position = CGPoint(x: 0.0, y: -self.size.height/13)
        self.addChild(player)
        player.zPosition = 5.0*/
        
        //intel.player = player
        //checkLives()
    }
    
    override func update(_ currentTime: TimeInterval) {
    }
}

extension GameSceneWatch: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        print("It's over!")
    }
}
