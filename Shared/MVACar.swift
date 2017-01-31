//
//  PlayerCar.swift
//  (un)Predictable
//
//  Created by Majo on 30/10/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit

enum MVAPosition {
    /*
     car = ⍓
     
     FL | F | FR
     –––––––––--
      L | ⍓ | R
     -----------
     BL | B | BR
     */
    case frontLeft, front, frontRight
    case right, left
    case backLeft, back, backRight
}

class MVACar: SKSpriteNode {
    
    var mindSet: MVAMindSet
    var pointsPerSecond = 0.0
    var timeToChangeLane = Double.randomWith2Decimals(inRange: 1..<3)
    var timeToChangeSpeed = Double.randomWith2Decimals(inRange: 1..<2)

    func timeCountdown(deltaT: Double) {
        timeToChangeLane -= deltaT
        timeToChangeSpeed -= deltaT
        cantMoveForXTime -= deltaT
    }
    
    private var roadLanes: [Int:CGFloat] {
        get {
            return (self.parent as? GameScene)?.lanes ?? [:]
        }
    }
    
    var isMoving = false
    var checked = false
    
    var currentLane: Int!
    var cantMoveForXTime = 0.0
    var wantsToChangeLane = false
    
    private var topCenterSensor: CGPoint {
        get {
            return CGPoint(x: position.x, y: position.y+(size.height/2)+30.0)
        }
    }
    
    private var rightSensors: [CGPoint] {
        get {
            let topRight = CGPoint(x: position.x+size.width, y: position.y+size.height/2+20)
            let centerRight = CGPoint(x: position.x+size.width, y: position.y)
            let bottomRight = CGPoint(x: position.x+size.width, y: position.y-size.height/2-20)
            return [topRight,centerRight,bottomRight]
        }
    }
    
    private var leftSensors: [CGPoint] {
        get {
            let topLeft = CGPoint(x: position.x-size.width, y: position.y+size.height/2+20)
            let centerLeft = CGPoint(x: position.x-size.width, y: position.y)
            let bottomLeft = CGPoint(x: position.x-size.width, y: position.y-size.height/2-20)
            return [topLeft,centerLeft,bottomLeft]
        }
    }
    
    private var rightDiagonalSensorRange: [CGPoint] {
        get {
            let rightDiagUP = CGPoint(x: position.x+(size.width), y: position.y+180)
            let rightDiagC = CGPoint(x: position.x+(size.width), y: position.y+75)
            return rightSensors+[rightDiagUP,rightDiagC]
        }
    }
    
    private var leftDiagonalSensorRange: [CGPoint] {
        get {
            let leftDiagUP = CGPoint(x: position.x-(size.width), y: position.y+180)
            let leftDiagC = CGPoint(x: position.x-(size.width), y: position.y+75)
            return leftSensors+[leftDiagUP,leftDiagC]
        }
    }
    //!!! sensors change with width! must be static?
    init(withSize size: CGSize, andMindSet mindSet: MVAMindSet, color: UIColor) {
        self.mindSet = mindSet
        super.init(texture: nil, color: color, size: CGSize(width: 60.0, height: 100.0))
        if mindSet == .player {
            for point in rightSensors+leftSensors+[topCenterSensor]+rightDiagonalSensorRange+leftDiagonalSensorRange {
                let dot = SKSpriteNode(color: .red, size: CGSize(width: 5.0, height: 5.0))
                dot.position = point
                addChild(dot)
            }
        }
        
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 60.0, height: 100.0))
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
    
    func diagonalRight() -> Set<MVACar> {
        var collidingCars = Set<MVACar>()
        for sensor in rightDiagonalSensorRange {
            if let nodes = parent?.nodes(at: sensor).filter({ $0 is MVACar }) {
                collidingCars = collidingCars.union(Set(nodes.map({ $0 as! MVACar }).filter({ $0 != self })))
            }
        }
        return Set(collidingCars.filter({ $0.mindSet != .player }))
    }
    
    func diagonalLeft() -> Set<MVACar> {
        var collidingCars = Set<MVACar>()
        for sensor in leftDiagonalSensorRange {
            if let nodes = parent?.nodes(at: sensor).filter({ $0 is MVACar }) {
                collidingCars = collidingCars.union(Set(nodes.map({ $0 as! MVACar }).filter({ $0 != self })))
            }
        }
        return Set(collidingCars.filter({ $0.mindSet != .player }))
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
    
}
