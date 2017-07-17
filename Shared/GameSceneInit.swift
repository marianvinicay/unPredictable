//
//  GameSceneInit.swift
//  (un)Predictable
//
//  Created by Majo on 17/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

extension GameScene {
    class func new(withSize deviceSize: CGSize) -> GameScene {
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
        scene.camera = (scene.childNode(withName: "cam") as! SKCameraNode)
        
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
        (scene.camera!.childNode(withName: "over") as! SKSpriteNode).size = scene.size
        
        scene.recordDistance = scene.camera!.childNode(withName: "best") as! SKLabelNode
        if let best = MVAMemory.maxPlayerDistance?.roundTo(NDecimals: 1) {
            scene.recordDistance.text = "BEST: \(best) KM"
        }
        
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
            let starterNode = MVARoadNode.createWith(texture: SKTexture(imageNamed: "Start1"), height: self.size.height, andWidth: self.size.width)
            starterNode.position = .zero
            roadNodes.insert(starterNode)
            endOfWorld = starterNode.position.y+starterNode.size.height
            self.addChild(starterNode)
        }
        
        let start2Texture = SKTexture(imageNamed: "Start2")
        for _ in 0..<3 {
            let road = MVARoadNode.createWith(texture: start2Texture, height: self.size.height, andWidth: self.size.width)
            switch arc4random_uniform(2) {
            case 1:
                let pSpot = arc4random_uniform(2) == 0 ? SKSpriteNode(imageNamed: "ParkingSpotR"):SKSpriteNode(imageNamed: "ParkingSpotL")
                pSpot.anchorPoint.y = 1.0
                pSpot.size = pSpot.size.adjustSize(toNewWidth: road.size.width)
                pSpot.position = CGPoint(x: 0.0, y: CGFloat(arc4random_uniform(UInt32(road.size.height-pSpot.size.height))))
                pSpot.zPosition = 1.0
                road.addChild(pSpot)
            default: break
            }
            road.position.x = 0.0
            road.position.y = endOfWorld!
            endOfWorld = road.position.y+road.size.height
            roadNodes.insert(road)
            self.addChild(road)
        }
        
        let road = MVARoadNode.createWith(texture: spawner.roadTexture, height: self.size.height*1.5, andWidth: self.size.width)
        road.position.x = 0.0
        road.position.y = endOfWorld!+self.size.height*0.25
        roadNodes.insert(road)
        self.addChild(road)
        
        lanePositions = road.laneCoordinates
    }
    
    func initiateScene() {
        spawner = MVASpawner.createCarSpawner(withSize: CGSize(width: size.width, height: MVAConstants.baseCarSize.height*2.5))
        spawner.position = CGPoint(x: 0.0, y: self.frame.height*1.5)
        spawner.zPosition = 4.0
        spawner.name = "spawner"
        self.addChild(spawner)
        
        spawnPlayer()
        setLevelSpeed(0)
        spawnStartRoad()
        
        //remover
        remover = SKSpriteNode(color: .clear, size: CGSize(width: size.width, height: 5.0))
        remover.position = CGPoint(x: 0.0, y: -frame.height)
        remover.zPosition = 4.0
        remover.name = "remover"
        self.addChild(remover)
        
        remover.physicsBody = SKPhysicsBody(rectangleOf: remover.size)
        remover.physicsBody?.affectedByGravity = false
        remover.physicsBody?.isDynamic = false
        remover.physicsBody?.categoryBitMask = MVAPhysicsCategory.remover.rawValue
        remover.physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue
        
        self.audioEngine.prepare()
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.speed = 1.0
        
        sound.ignite(node: self)
    }
    
    func resetScene() {
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
        
        if MVAMemory.maxPlayerDistance ?? 0.0 < intel.distanceTraveled {
            MVAMemory.maxPlayerDistance = intel.distanceTraveled
            self.recordDistance.text = "BEST: \(intel.distanceTraveled.roundTo(NDecimals: 1)) KM"
        }
        intel.reset()
        spawnPlayer()
        
        endOfWorld = 0.0
        spawnStartRoad()
        
        spawner.size.height = MVAConstants.baseCarSize.height*2.5
        remover.position = CGPoint(x: 0.0, y: -frame.height)
        physicsWorld.speed = 1.0
    }
}
