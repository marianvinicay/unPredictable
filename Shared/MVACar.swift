//
//  PlayerCar.swift
//  (un)Predictable
//
//  Created by Majo on 30/10/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit

enum MVADirection: CustomStringConvertible {
    case topRight,topLeft,centerRight,centerLeft,bottomRight,bottomLeft
    
    var description: String {
        get {
            var str = "nil"
            switch self {
            case .topRight: str = "topRight"
            case .topLeft: str = "topLeft"
            case .centerRight: str = "centerRight"
            case .centerLeft: str = "centerLeft"
            case .bottomRight: str = "bottomRight"
            case .bottomLeft: str = "bottomLeft"
            }
            return str
        }
    }
}

class MVACar: MVAMarvinEntity {
    
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
            let bottomRight = CGPoint(x: position.x+(size.width), y: position.y-(size.height))
            let bottomLeft = CGPoint(x: position.x-(size.width), y: position.y-(size.height))
            return [.topRight:topRight,.topLeft:topLeft,.centerRight:centerRight,.centerLeft:centerLeft,.bottomRight:bottomRight,.bottomLeft:bottomLeft]
        }
    }
    
    init(withMindSet mSet: MVAMindSet) {
        super.init(withSize: CGSize(width: 69.0, height: 150.0), andMindSet: .player, color: UIColor.red)
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
    
    func nearestCars() -> [MVADirection:Set<MVACar>] {
        var cars = [MVADirection:Set<MVACar>]()
        for point in detectorPoints {
            if let nodes = parent?.nodes(at: point.value).filter({ $0 is MVACar }) {
                var lessNodes = Set(nodes.map({ $0 as! MVACar }))
                lessNodes.remove(self)
                cars[point.key] = lessNodes//???
            }
        }
        return cars
    }
    
}
