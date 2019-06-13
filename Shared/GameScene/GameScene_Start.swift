//
//  GameScene_Start.swift
//  unPredictable
//
//  Created by Marian Vinicay on 17/07/2017.
//  Copyright © 2017 Marvin. All rights reserved.
//

import SpriteKit

extension GameScene {
    private func addIphoneXInset() {
        let node = SKSpriteNode(color: .black, size: CGSize(width: self.size.width, height: 30.0))
        node.anchorPoint.y = 0.0
        node.position.x = 0.0
        node.position.y = -self.size.height/2
        node.name = "iphoneX"
        node.zPosition = 6.0
        self.camera!.addChild(node)
    }
    
    class func new(withSize deviceSize: CGSize) -> GameScene {
        guard let scene = GameScene(fileNamed: "GameScene") else {
            abort()
        }

        scene.scaleMode = .aspectFill
        scene.size = deviceSize
        scene.camera = (scene.childNode(withName: "cam") as! SKCameraNode)
        scene.backgroundColor = MVAColor.roadGreen
        if arc4random_uniform(4) == 3 {
            scene.backgroundColor = MVAColor.roadBrown
        }
        
        scene.playBtt = scene.camera!.childNode(withName: "playBtt") as? SKSpriteNode
        scene.pauseBtt = scene.camera!.childNode(withName: "stop") as? SKSpriteNode
        scene.originalPausePosition = CGPoint(x: (scene.size.width/2)-10, y: (scene.size.height/2)-10)
        scene.pauseBtt.position = scene.originalPausePosition
        
        scene.speedSign = scene.camera!.childNode(withName: "speed") as? SKSpriteNode
        scene.originalSpeedPosition = CGPoint(x: (-(scene.size.width/2)+scene.speedSign.size.width/2)+5, y: ((scene.size.height/2)-scene.speedSign.size.height/2)-5)
        scene.speedSign.position = scene.originalSpeedPosition
        
        let downY: CGFloat = MVAMemory.isIphoneX ? 30.0:0.0
        
        scene.distanceSign = scene.camera!.childNode(withName: "distance") as? SKSpriteNode
        scene.originalDistancePosition = CGPoint(x: -scene.size.width/2, y: (-scene.size.height/2)+downY)
        scene.distanceSign.position = scene.originalDistancePosition
        let over = scene.camera!.childNode(withName: "over") as! SKSpriteNode
        over.position = .zero
        over.size = scene.size
        let down = scene.camera!.childNode(withName: "down") as! SKSpriteNode
        down.position = CGPoint(x: 0.0, y: (-scene.size.height/2)+downY)
        down.size.width = scene.size.width
        
        if downY > 0.0 {
            scene.addIphoneXInset()
        }
        
        scene.lives = down.childNode(withName: "lives") as? SKSpriteNode
        scene.lives.position = CGPoint(x: scene.size.width/2, y: 0.0)
        scene.lives.isHidden = true
        scene.battery = down.childNode(withName: "battery") as? SKSpriteNode
        scene.battery.position = CGPoint(x: (scene.size.width/2)-8, y: 8.0)
        scene.battery.isHidden = true
        
        scene.recordDistance = scene.camera!.childNode(withName: "best") as? SKLabelNode
        let bestDist = MVAMemory.maxPlayerDistance.roundTo(NDecimals: 1)
        if bestDist != 0.0 {
            scene.recordDistance.text = "BEST: \(bestDist) \(MVAWorldConverter.lengthUnit)"
        } else {
            scene.recordDistance.text = ""
        }
        
        scene.setLevelSpeed(0)
        scene.setDistance(MVAWorldConverter.distanceToOdometer(0.0))
        
        scene.hideHUD(animated: false)
        scene.initiateScene()
        return scene
    }
    
    func spawnPlayer() {
        let pSkin = MVASkin.createForCar(MVAMemory.playerCar, withAtlas: spawner.textures)
        let player = MVACarPlayer.new(withSkin: pSkin)
        player.physicsBody?.categoryBitMask = MVAPhysicsCategory.player.rawValue
        player.physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue
        player.physicsBody?.collisionBitMask = MVAPhysicsCategory.car.rawValue
        player.physicsBody?.isDynamic = true
        player.position = CGPoint(x: 0.0, y: -self.size.height/13)
        if lanePositions.count == 4 {
            player.position.y = -self.size.height/23
        }
        self.addChild(player)
        player.zPosition = 5.0
        intel.player = player
        checkLives()
    }
    
    func spawnStartRoad() {
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
            road.position = CGPoint(x: 0.0, y: endOfWorld!)
            endOfWorld = road.position.y+road.size.height
            roadNodes.insert(road)
            self.addChild(road)
        }
        
        //let tutDisp = gameControls != .sphero ? MVAMemory.tutorialDisplayed : MVAMemory.spheroTutorialDisplayed
        if MVAMemory.tutorialDisplayed {
            for i in 0..<2 {
                let road = MVARoadNode.createWith(texture: spawner.roadTexture, height: self.size.height*1.5, andWidth: self.size.width)
                road.position = CGPoint(x: 0.0, y: endOfWorld!)
                if i == 0 {
                    endOfWorld = road.position.y+road.size.height
                }
                roadNodes.insert(road)
                self.addChild(road)
            }
        }
    }
    
    func initiateScene() {
        spawner = MVASpawnerNode.createCarSpawner(withSize: CGSize(width: size.width, height: MVAConstants.baseCarSize.height*2.5))
        spawner.position = CGPoint(x: 0.0, y: frame.height*1.5)
        spawner.zPosition = 4.0
        self.addChild(spawner)
        
        spawnStartRoad()
        setLevelSpeed(0)
        spawnPlayer()
        
        remover = MVARemoverNode.createRemover(withSize: CGSize(width: size.width, height: MVAConstants.baseCarSize.height))
        remover.position = CGPoint(x: 0.0, y: -frame.height)
        remover.zPosition = 4.0
        self.addChild(remover)
        
        self.audioEngine.prepare()
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.speed = 0.0
        
        intel.sound.ignite(node: self)
    }
}
