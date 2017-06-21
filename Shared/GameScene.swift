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
    var roadNodes = Set<MVARoadNode>()
    var lanePositions = [Int:CGFloat]()
    var cameraNode: SKCameraNode!
    let intel = MVAMarvinAI()
    var endOfWorld: CGFloat = 0.0
    var remover: SKSpriteNode!
    var spawner: MVACarSpawner!
    
    var playBtt: SKLabelNode!
    
    class func newGameScene(withSize deviceSize: CGSize) -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        //let scene = GameScene(size: size)
        guard let scene = GameScene(fileNamed: "GameScene") else {
            print("Failed to load GameScene.sks")
            abort()
        }
        scene.playBtt = scene.childNode(withName: "playBtt") as! SKLabelNode
        scene.playBtt.position.x = scene.size.width/2
        scene.scaleMode = .aspectFill
        scene.initiateScene()
        return scene
    }
    
    private func initiateScene() {
        let road = MVARoadNode.createWith(numberOfLanes: 3, height: size.height, andWidth: size.width)
        road.position.x = self.size.width/2
        roadNodes.insert(road)
        endOfWorld = road.position.y+road.size.height/2
        lanePositions = road.laneXCoordinate
        self.addChild(road)
        
        cameraNode = SKCameraNode()
        cameraNode.position.x = frame.size.width/2
        self.camera = cameraNode
        
        let player = MVACar(withSize: CGSize(), andMindSet: .pseudoPlayer, img: "Audi")
        player.physicsBody?.categoryBitMask = MVAPhysicsCategory.player.rawValue
        player.physicsBody?.collisionBitMask = MVAPhysicsCategory.car.rawValue
        player.physicsBody?.collisionBitMask = MVAPhysicsCategory.car.rawValue
        player.physicsBody?.isDynamic = false
        let lane = Int(arc4random_uniform(road.numberOfLanes))
        player.position = CGPoint(x: road.laneXCoordinate[lane]!, y: size.height/3)
        player.currentLane = lane
        self.addChild(player)
        player.zPosition = 1.0
        player.pointsPerSecond = 250
        let move = SKAction.moveBy(x: 0.0, y: CGFloat(player.pointsPerSecond), duration: 1.0)
        player.run(SKAction.repeatForever(move), withKey: "move")//???
        intel.player = player
        intel.cars.insert(player)
        
        spawner = MVACarSpawner.createSpawner(withWidth: frame.width)
        spawner.anchorPoint.x = 0.0
        spawner.position = CGPoint(x: 0.0, y: frame.height)//!!!diff from camera move
        self.addChild(spawner)
        let spawn = SKAction.run {
            self.spawner.spawn(withExistingCars: self.intel.cars, roadLanes: self.lanePositions)
        }
        
        let wait = SKAction.wait(forDuration: 2.5)
        self.run(SKAction.repeatForever(SKAction.sequence([spawn,wait])), withKey: "spawn")
        
        //remover
        remover = SKSpriteNode(color: .purple, size: CGSize(width: frame.width, height: 10.0))
        remover.position.x = frame.width/2
        remover.position.y = -frame.height/3
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
        lastUpdate = currentTime
        
        cameraNode.position.y = intel.player.position.y+size.height/4
        playBtt.position.y = cameraNode.position.y
        if endOfWorld-50<self.cameraNode.position.y+self.size.height/2 {
            let road = MVARoadNode.createWith(numberOfLanes: 3, height: self.size.height, andWidth: self.size.width)
            road.position.x = self.size.width/2
            road.position.y = endOfWorld+road.size.height/2
            self.addChild(road)
            roadNodes.insert(road)
            endOfWorld += road.size.height
        }
        remover.position.y = -self.frame.size.height
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
        guard intel.player.mindSet == .player else { return }
        _ = intel.player.changeLane(inDirection: swipe, withPlayer: intel.player)
    }
    
    private var brakingTimer: Timer!
    func handleBrake(started: Bool) {
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
    internal var lastPressedXPosition: CGFloat!
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene: UIGestureRecognizerDelegate {
    
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
        switch swipe.direction {
        case UISwipeGestureRecognizerDirection.right: self.handleSwipe(swipe: .right)
        case UISwipeGestureRecognizerDirection.left: self.handleSwipe(swipe: .left)
        default: break
        }
    }
    //??? what is internal?
    internal func handleUIBrake(gest: UILongPressGestureRecognizer) {
        switch gest.state {
        case .began:
            self.handleBrake(started: true)
            lastPressedXPosition = gest.location(in: self.view).x
        case .changed:
            if lastPressedXPosition+60 < gest.location(in: self.view).x {
                self.handleSwipe(swipe: .right)
                lastPressedXPosition = gest.location(in: self.view).x
            } else if lastPressedXPosition-60 > gest.location(in: self.view).x {
                self.handleSwipe(swipe: .left)
                lastPressedXPosition = gest.location(in: self.view).x
            }
        case .ended: self.handleBrake(started: false)
        default: break
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if playBtt.contains(touches.first!.location(in: self)) {
            playBtt.run(SKAction.scale(by: 10, duration: 2.0))
            intel.player.mindSet = .player
            intel.cars.remove(intel.player)
            playBtt.removeFromParent()
            intel.player.changeSpeed(220)
            self.removeAction(forKey: "spawn")
            let spawn = SKAction.run {
                self.spawner.spawn(withExistingCars: self.intel.cars, roadLanes: self.lanePositions)
            }
            let wait = SKAction.wait(forDuration: 1.9)
            self.run(SKAction.repeatForever(SKAction.sequence([spawn,wait])), withKey: "spawn")
        }
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

