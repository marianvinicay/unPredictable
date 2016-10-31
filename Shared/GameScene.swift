//
//  GameScene.swift
//  (un)Predictable
//
//  Created by Majo on 25/08/16.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit
import GameplayKit
import UIKit

#if os(watchOS)
    import WatchKit
    // <rdar://problem/26756207> SKColor typealias does not seem to be exposed on watchOS SpriteKit
    typealias SKColor = UIColor
#endif

class GameScene: SKScene {
    
    private var road: SKSpriteNode!
    private var cameraNode: SKCameraNode!
    internal var player: MVACar!
    internal var bot: MVACar!
    internal let gameLogic = MVAGameLogic()
    private var endOfWorld: CGFloat = 0.0
    
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
        var lastPosition: CGFloat!
        scene.enumerateChildNodes(withName: "road") { (node: SKNode, err: UnsafeMutablePointer<ObjCBool>) in
            print(err)
            lastPosition = (node.position.y+(node as! SKSpriteNode).size.height)
        }
        print("xy",lastPosition)
        scene.endOfWorld = lastPosition
        
        scene.scaleMode = .aspectFill
        
        scene.cameraNode = SKCameraNode()
        scene.cameraNode.position.x = scene.frame.size.width/2
        scene.camera = scene.cameraNode
        let car = MVACar.create(withMindSet: .player)
        car.position = CGPoint(x: scene.frame.width/2, y: 80)
        scene.addChild(car)
        car.zPosition = 1.0
        let move = SKAction.move(by: CGVector(dx: 0.0, dy: 50), duration: 3.0)
        car.run(SKAction.repeatForever(move))
        scene.player = car
        scene.gameLogic.currentLane = .other
        
        let bot = MVACar.create(withMindSet: .bot)
        bot.zPosition = 1.0
        bot.position = CGPoint(x: (scene.frame.width/2)-80, y: 69)
        bot.run(SKAction.repeatForever(move))
        scene.bot = bot
        scene.addChild(bot)
        
        return scene
    }
    
    func startAI() {
        let goal = GKGoal(toInterceptAgent: player.agent, maxPredictionTime: 0.0)
        //let avoid = GKGoal(toAvoidAgents: Array(decoys).map({$0.agent!}), maxPredictionTime: 5.0)
        //let speed = GKGoal(toReachTargetSpeed: player.agent.velocity.y)
        bot.agent.behavior = GKBehavior(goals: [goal], andWeights: [1.0])
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
        // Called before each frame is rendered
        bot.agent.update(deltaTime: currentTime-lastUpdate)
        player.agent.update(deltaTime: currentTime-lastUpdate)
        lastUpdate = currentTime
        
        cameraNode.position.y = player.position.y
        if endOfWorld-50<self.cameraNode.position.y+self.size.height/2 {
            let road = MVARoadNode.createWith(numberOfLanes: 3, height: self.size.height, andWidth: self.size.width)
            road.position.y = endOfWorld-10
            self.addChild(road)
            endOfWorld += road.size.height-10
        }
        //enum!!!
        enumerateChildNodes(withName: "road") { (node: SKNode, err: UnsafeMutablePointer<ObjCBool>) in
            let roadPosition = node.position.y+(node as! SKSpriteNode).size.height
            if roadPosition < (self.cameraNode.position.y-self.size.height/2)-10 {
                print("remove")
                node.removeFromParent()
            }
        }
    }
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {
    internal func setupSwipes() {
        let right = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(swipe:)))
        right.direction = .right
        let left = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(swipe:)))
        left.direction = .left
        let up = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(swipe:)))
        up.direction = .up
        let down = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(swipe:)))
        down.direction = .down
        self.view?.addGestureRecognizer(right)
        self.view?.addGestureRecognizer(left)
        self.view?.addGestureRecognizer(up)
        self.view?.addGestureRecognizer(down)
    }
    func handleSwipe(swipe: UISwipeGestureRecognizer) {
        if swipe.direction == .up {
            let boost = SKAction.moveBy(x: 0.0, y: 200.0, duration: 0.5)
            self.player.run(boost)
        } else if swipe.direction == .down {
            startAI()
            let slow = SKAction.moveBy(x: 0.0, y: -20.0, duration: 0.5)
            self.player.run(slow)
        } else {
            switch gameLogic.currentLane! {
            case .lastLeft:
                if swipe.direction == .right {
                    let rightLane = CGFloat(70)
                    let moveRight = SKAction.moveBy(x: rightLane, y: 0.0, duration: 1.0)
                    //gameLogic.currentLane = RoadLanes.Middle
                    player.run(moveRight)
                }
            case .other:
                if swipe.direction == .right {
                    let rightLane = CGFloat(70)
                    let moveRight = SKAction.moveBy(x: rightLane, y: 0.0, duration: 1.0)
                    //gameLogic.currentLane = RoadLanes.Middle
                    player.run(moveRight)
                } else {
                    let leftLane = CGFloat(-70)
                    let moveLeft = SKAction.moveBy(x: leftLane, y: 0.0, duration: 1.0)
                    //gameLogic.currentLane = RoadLanes.Left
                    player.run(moveLeft)
                }
            case .lastRight:
                if swipe.direction == .left {
                    let leftLane = CGFloat(-70)
                    let moveLeft = SKAction.moveBy(x: leftLane, y: 0.0, duration: 1.0)
                    //gameLogic.currentLane = RoadLanes.Left
                    player.run(moveLeft)
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
        }
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

