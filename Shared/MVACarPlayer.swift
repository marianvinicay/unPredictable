//
//  PlayerCar.swift
//  (un)Predictable
//
//  Created by Majo on 30/10/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit
import GameplayKit

enum MVACarMindSet {
    case player
    case bot
    case decoy
}

class MVACar: SKSpriteNode, GKAgentDelegate {
    var mindSet: MVACarMindSet!
    let agent = GKAgent2D()
    
    class func create(withMindSet mSet: MVACarMindSet) -> MVACar {
        let car = MVACar(color: UIColor.red, size: CGSize(width: 69.0, height: 150.0))
        car.mindSet = mSet
        if car.mindSet == .bot {
            car.color = UIColor.blue
        } else if car.mindSet == .decoy {
            car.color = UIColor.brown
        }
        
        let carEntity = GKEntity()
        // An agent to manage the movement of this node in a scene.
        car.agent.radius = 2.0;
        car.agent.position = float2(x: Float(car.position.x), y: Float(car.position.y))
        car.agent.maxSpeed = 100
        car.agent.maxAcceleration = 50
        car.agent.delegate = car
        carEntity.addComponent(car.agent)
        
        car.entity = carEntity
        car.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 69.0, height: 150.0))
        car.physicsBody?.collisionBitMask = 1
        car.physicsBody?.categoryBitMask = 0
        //car.physicsBody?.isDynamic = false
        car.physicsBody?.affectedByGravity = false
        car.physicsBody?.allowsRotation = false
        
        return car
    }
    
    func agentWillUpdate(_ agent: GKAgent) {
        if let ag = agent as? GKAgent2D {
            ag.position.x = Float(self.position.x)
            ag.position.y = Float(self.position.y)
        }
    }
    
    func agentDidUpdate(_ agent: GKAgent) {
        if let ag = agent as? GKAgent2D {
            //if mindSet.currentState is PlayerCar == false {
            if mindSet != .player {
                self.position.y = CGFloat(ag.position.y)
                self.position.x = CGFloat(ag.position.x)
            }
        }
    }
}
