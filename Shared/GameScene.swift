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

extension UIColor {
    class func getRandomColor() -> UIColor {
        let randomRed:CGFloat = CGFloat(drand48())
        let randomGreen:CGFloat = CGFloat(drand48())
        let randomBlue:CGFloat = CGFloat(drand48())
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
}

enum MVAPhysicsCategory: UInt32 {
    case car = 1
    case remover = 2
    case spawner = 3
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    //internal ?? private ??
    var road: MVARoadNode!
    var roadNodes = Set<MVARoadNode>()
    var lanePositions = [Int:CGFloat]()
    var cameraNode: SKCameraNode!
    var player: MVACar!
    var bots /*Set<MVACar>*/ = [MVACar]()
    let gameLogic = MVAGameLogic()
    let intel = MVAMarvinAI()
    var endOfWorld: CGFloat = 0.0
    var remover: SKSpriteNode!
    var spawner: MVACarSpawner!
    
    class func newGameScene(withSize size: CGSize) -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        //let scene = GameScene(size: size)
        guard let scene = GameScene(fileNamed: "GameScene") else {
            print("Failed to load GameScene.sks")
            abort()
        }
        // Set the scale mode to scale to fit the window
        
        //scene.cameraNode = SKCameraNode()
        //scene.camera = scene.cameraNode
        scene.road = MVARoadNode.createWith(numberOfLanes: 3, height: scene.size.height, andWidth: scene.size.width)
        scene.road.position = CGPoint.zero
        scene.roadNodes.insert(scene.road)
        scene.endOfWorld = (scene.road.position.y+scene.road.size.height)
        scene.lanePositions = scene.road.laneXCoordinate
        scene.addChild(scene.road)
        
        scene.scaleMode = .aspectFill
        
        scene.cameraNode = SKCameraNode()
        scene.cameraNode.position.x = scene.frame.size.width/2
        scene.camera = scene.cameraNode
        let car = MVACar(withSize: CGSize(), andMindSet: .player, color: .blue)
        car.physicsBody?.categoryBitMask = 33
        let lane = Int(arc4random_uniform(scene.road.numberOfLanes))
        car.position = CGPoint(x: scene.road.laneXCoordinate[lane]!, y: size.height/3)
        car.currentLane = lane
        scene.addChild(car)
        car.zPosition = 1.0
        car.pointsPerSecond = 200
        let move = SKAction.moveBy(x: 0.0, y: CGFloat(car.pointsPerSecond), duration: 1.0)
        car.run(SKAction.repeatForever(move), withKey: "move")//???
        scene.player = car
        scene.gameLogic.currentLane = lane
        scene.intel.player = car
        
        let spawn = SKAction.run {
            scene.spawner.spawn(withExistingCars: scene.bots, roadLanes: scene.lanePositions)
        }
        let wait = SKAction.wait(forDuration: 1.0)
        scene.run(SKAction.repeatForever(SKAction.sequence([spawn,wait])))
        
        //remover
        let remover = SKSpriteNode(color: .purple, size: CGSize(width: scene.frame.width, height: 10.0))
        remover.position.x = scene.frame.width/2
        remover.position.y = -scene.frame.height
        scene.addChild(remover)
        scene.remover = remover
        remover.physicsBody = SKPhysicsBody(rectangleOf: remover.size)
        remover.physicsBody?.affectedByGravity = false
        remover.physicsBody?.isDynamic = false
        remover.physicsBody?.categoryBitMask = MVAPhysicsCategory.remover.rawValue
        remover.physicsBody?.collisionBitMask = MVAPhysicsCategory.car.rawValue
        remover.physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue
        scene.physicsWorld.contactDelegate = scene
        
        let spawner = MVACarSpawner.createSpawner(withWidth: scene.frame.width)
        spawner.anchorPoint.x = 0.0
        spawner.position = CGPoint(x: 0.0, y: scene.frame.height)//!!!diff from camera move
        scene.addChild(spawner)
        scene.spawner = spawner
        
        return scene
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactN = [contact.bodyA.categoryBitMask,contact.bodyB.categoryBitMask]
        if contactN.contains(MVAPhysicsCategory.car.rawValue) && contactN.contains(MVAPhysicsCategory.remover.rawValue) {
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
        } else if contactN.contains(MVAPhysicsCategory.car.rawValue) && contactN.contains(MVAPhysicsCategory.spawner.rawValue) {
            print("spawner")
        }
    }
    
    func setUpScene() {
        #if os(iOS) || os(tvOS)
            self.setupSwipes()
        #elseif os(watchOS)
            
        #endif
    }
    
    #if os(watchOS)
    override func sceneDidLoad() {
        self.setUpScene()
    }
    #else
    override func didMove(to view: SKView) {
        self.setUpScene()
    }
    #endif
    
    private var lastUpdate = 0.0//Double
    override func update(_ currentTime: TimeInterval) {
        if currentTime-lastUpdate < 10 {//??? firstLoad run time
            intel.update(withDeltaTime: currentTime-lastUpdate)
        }
        /*
        // Called before each frame is rendered
        player.agent.update(deltaTime: currentTime-lastUpdate)
        for dec in bots {
            dec.agent.update(deltaTime: currentTime-lastUpdate)
        }*/
        lastUpdate = currentTime
        
        cameraNode.position.y = player.position.y+size.height/4
        if endOfWorld-50<self.cameraNode.position.y+self.size.height/2 {
            let road = MVARoadNode.createWith(numberOfLanes: 3, height: self.size.height, andWidth: self.size.width)
            road.position.y = endOfWorld-10
            self.addChild(road)
            roadNodes.insert(road)
            endOfWorld += road.size.height-10
        }
        remover.position.y = cameraNode.position.y-self.frame.size.height
        spawner.position.y = cameraNode.position.y+self.frame.size.height
        
        //then try enumerate nodes with name road
        for road in roadNodes {
            let roadPosition = road.position.y+road.size.height
            if roadPosition < (self.cameraNode.position.y-self.size.height/2)-10 {
                road.removeFromParent()
            }
        }
    }
    
    func handleSwipe(swipe: MVAPosition) {
        _ = player.changeLane(inDirection: swipe)
    }
    
    func handleBrake(started: Bool) {
        if started {
            player.pointsPerSecond /= 3
            if let act = player.action(forKey: "move") {
                act.speed /= 100 //??? or new SKAction?
            }
        } else if started == false {//??? is == false necessary
            player.pointsPerSecond *= 3
            if let act = player.action(forKey: "move") {
                act.speed *= 100
            }
        }
    }
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UILongPressGestureRecognizer {
            return true
        }
        return false
    }
    
    internal func setupSwipes() {
        let right = UISwipeGestureRecognizer(target: self, action: #selector(handelUISwipe(swipe:)))
        right.direction = .right
        let left = UISwipeGestureRecognizer(target: self, action: #selector(handelUISwipe(swipe:)))
        left.direction = .left
        let brake = UILongPressGestureRecognizer(target: self, action: #selector(handleUIBrake(gest:)))
        brake.minimumPressDuration = 0.1
        right.delegate = self
        left.delegate = self
        brake.delegate = self
        self.view?.addGestureRecognizer(right)
        self.view?.addGestureRecognizer(left)
        self.view?.addGestureRecognizer(brake)
    }
    
    internal func handelUISwipe(swipe: UISwipeGestureRecognizer) {
        if swipe.direction == .right {
            self.handleSwipe(swipe: .right)
        } else if swipe.direction == .left {
            self.handleSwipe(swipe: .left)
        }
    }
    //??? what is internal?
    internal func handleUIBrake(gest: UILongPressGestureRecognizer) {
        if gest.state == .began {
            self.handleBrake(started: true)
        } else if gest.state == .ended {
            self.handleBrake(started: false)//start/stop braking func?
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
   
}
#endif

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

