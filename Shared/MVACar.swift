//
//  PlayerCar.swift
//  (un)Predictable
//
//  Created by Majo on 30/10/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit

enum MVADirection: CustomStringConvertible {
    case topRight, topLeft
    case centerTop
    case centerRight, centerLeft
    
    var description: String {
        get {
            switch self {
            case .topRight: return "topRight"
            case .topLeft: return "topLeft"
            case .centerRight: return "centerRight"
            case .centerLeft: return "centerLeft"
            case .centerTop: return "centerTop"
            }
        }
    }
}

class MVACar: SKSpriteNode {
    
    var mindSet: MVAMindSet
    var pointsPerSecond = 0.0
    var doSomethingTime = Double(arc4random_uniform(3)+2)
    
    private var roadLanes: [Int:CGFloat] {
        get {
            return (self.parent as? GameScene)?.lanes ?? [:]
        }
    }
    
    var isMoving = false
    
    var currentLane: Int!
    private var detectorPoints: [MVADirection:CGPoint] {
        get {
            let topRight = CGPoint(x: position.x+(size.width), y: position.y+(size.height))
            let topLeft = CGPoint(x: position.x-(size.width), y: position.y+(size.height))
            let centerRight = CGPoint(x: position.x+(size.width), y: position.y)
            let centerLeft = CGPoint(x: position.x-(size.width), y: position.y)
            let centerTop = CGPoint(x: position.x, y: position.y+(size.height/2)+30.0)
            return [.topRight:topRight,.topLeft:topLeft,.centerRight:centerRight,.centerLeft:centerLeft,.centerTop:centerTop]
        }
    }
    
    private var topCenterSensor: CGPoint {
        get {
            return CGPoint(x: position.x, y: position.y+(size.height/2)+30.0)
        }
    }
    
    private var rightSensors: [CGPoint] {
        get {
            let topRight = CGPoint(x: position.x+size.width, y: position.y+size.height/2)
            let bottomRight = CGPoint(x: position.x+size.width, y: position.y-size.height/2)
            return [topRight,bottomRight]
        }
    }
    
    private var leftSensors: [CGPoint] {
        get {
            let topLeft = CGPoint(x: position.x-size.width, y: position.y+size.height/2)
            let bottomLeft = CGPoint(x: position.x-size.width, y: position.y-size.height/2)
            return [topLeft,bottomLeft]
        }
    }
    
    init(withSize size: CGSize, andMindSet mindSet: MVAMindSet, color: UIColor) {
        self.mindSet = mindSet
        super.init(texture: nil, color: color, size: CGSize(width: 69.0, height: 150.0))
        for point in detectorPoints {
            let dot = SKSpriteNode(color: .red, size: CGSize(width: 5.0, height: 5.0))
            dot.position = point.value
            addChild(dot)
        }
                
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 69.0, height: 150.0))
        physicsBody?.collisionBitMask = 0
        physicsBody?.categoryBitMask = MVAPhysicsCategory.car.rawValue
        physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue
        physicsBody?.isDynamic = true
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
    }
    
    //???
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func change(lane: Int) {
        let newLane = currentLane+lane
        if self.roadLanes.keys.contains(newLane) {
            if let newLaneCoor = roadLanes[newLane] {
                self.isMoving = true
                currentLane = newLane
                let endMoving = SKAction.run({
                    self.isMoving = false
                })
                let move = SKAction.moveTo(x: newLaneCoor, duration: 0.25)
                self.run(SKAction.sequence([move,endMoving]))
            }
        }
    }
    
    func carInFront() -> MVACar? {
        if let nodes = parent?.nodes(at: topCenterSensor).filter({ $0 is MVACar }) {
            return Set(nodes.map({ $0 as! MVACar }).filter({ $0 != self })).first//???
        }
        return nil
    }
    
    //merge carsOn funcs?
    //maybe private funcs?
    func carsOnRight() -> Set<MVACar> {
        var collidingCars = Set<MVACar>()
        for sensor in rightSensors {
            if let nodes = parent?.nodes(at: sensor).filter({ $0 is MVACar }) {
                collidingCars = collidingCars.union(Set(nodes.map({ $0 as! MVACar }).filter({ $0 != self })))
            }
        }
        return collidingCars
    }
    
    func carsOnLeft() -> Set<MVACar> {
        var collidingCars = Set<MVACar>()
        for sensor in leftSensors {
            if let nodes = parent?.nodes(at: sensor).filter({ $0 is MVACar }) {
                collidingCars = collidingCars.union(Set(nodes.map({ $0 as! MVACar }).filter({ $0 != self })))
            }
        }
        return collidingCars
    }
    
    func nearestCars() -> [MVADirection:Set<MVACar>] {
        var cars = [MVADirection:Set<MVACar>]()
        for point in detectorPoints {
            if let nodes = parent?.nodes(at: point.value).filter({ $0 is MVACar }) {
                cars[point.key] = Set(nodes.map({ $0 as! MVACar }).filter({ $0 != self}))//???
            }
        }
        return cars
    }
    
}
