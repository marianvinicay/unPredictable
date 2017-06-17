//
//  GameScene.swift
//  (un)Predictable
//
//  Created by Majo on 25/08/16.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit
import UIKit

extension Collection where Indices.Iterator.Element == Index {
    
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

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
    case player = 2
    case remover = 3
    case spawner = 4
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
    
    class func newGameScene(withSize deviceSize: CGSize) -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        //let scene = GameScene(size: size)
        guard let scene = GameScene(fileNamed: "GameScene") else {
            print("Failed to load GameScene.sks")
            abort()
        }
        scene.initiateScene()
        return scene
    }
    
    private func initiateScene() {
        road = MVARoadNode.createWith(numberOfLanes: 3, height: size.height, andWidth: size.width)
        roadNodes.insert(road)
        endOfWorld = road.position.y+road.size.height
        lanePositions = road.laneXCoordinate
        self.addChild(road)
        
        //???
        self.scaleMode = .aspectFill
        
        cameraNode = SKCameraNode()
        cameraNode.position.x = frame.size.width/2
        self.camera = cameraNode
        
        let car = MVACar(withSize: CGSize(), andMindSet: .player, img: "Audi")
        car.physicsBody?.categoryBitMask = MVAPhysicsCategory.player.rawValue
        car.physicsBody?.collisionBitMask = MVAPhysicsCategory.car.rawValue
        car.physicsBody?.collisionBitMask = MVAPhysicsCategory.car.rawValue
        car.physicsBody?.isDynamic = false
        let lane = Int(arc4random_uniform(road.numberOfLanes))
        car.position = CGPoint(x: road.laneXCoordinate[lane]!, y: size.height/3)
        car.currentLane = lane
        self.addChild(car)
        car.zPosition = 1.0
        car.pointsPerSecond = 250
        let move = SKAction.moveBy(x: 0.0, y: CGFloat(car.pointsPerSecond), duration: 1.0)
        car.run(SKAction.repeatForever(move), withKey: "move")//???
        player = car
        gameLogic.currentLane = lane
        intel.player = car
        
        spawner = MVACarSpawner.createSpawner(withWidth: frame.width)
        spawner.anchorPoint.x = 0.0
        spawner.position = CGPoint(x: 0.0, y: frame.height)//!!!diff from camera move
        self.addChild(spawner)
        let spawn = SKAction.run {
            self.spawner.spawn(withExistingCars: self.bots, roadLanes: self.lanePositions)
        }
        
        let wait = SKAction.wait(forDuration: 1.8)
        self.run(SKAction.repeatForever(SKAction.sequence([spawn,wait])), withKey: "spawn")
        
        //remover
        remover = SKSpriteNode(color: .purple, size: CGSize(width: frame.width, height: 10.0))
        remover.position.x = frame.width/2
        remover.position.y = -frame.height
        self.addChild(remover)
        remover.physicsBody = SKPhysicsBody(rectangleOf: remover.size)
        remover.physicsBody?.affectedByGravity = false
        remover.physicsBody?.isDynamic = false
        remover.physicsBody?.categoryBitMask = MVAPhysicsCategory.remover.rawValue
        remover.physicsBody?.collisionBitMask = MVAPhysicsCategory.remover.rawValue
        remover.physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue
        self.physicsWorld.contactDelegate = self
    }
    
    func gameOver() {
        if player.childNode(withName: "txt") == nil {
            let label = SKLabelNode(text: "Game\nOver!")
            label.name = "txt"
            label.fontSize += 10	
            player.addChild(label)
            label.position.y += size.height/4
            self.isPaused = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { [unowned label] in
                self.isPaused = false
                self.player.removeChildren(in: [label])
            })
        }
    }
    
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
        _ = player.changeLane(inDirection: swipe, withPlayer: player)
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

