//
//  PlayerCar.swift
//  (un)Predictable
//
//  Created by Majo on 30/10/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//
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
    case back, backLeft, backRight
}

class MVACar: SKSpriteNode {
    
    var mindSet: MVAMindSet
    var pointsPerSecond: CGFloat = 0.0
    var timeToChangeLane = Double.randomWith2Decimals(inRange: 1..<3)
    var timeToChangeSpeed = Double.randomWith2Decimals(inRange: 1..<2)

    ///debug func
    func stampIt() {
        if self.children.count <= 2 {
        let node = SKSpriteNode(color: .red, size: CGSize(width: 20, height: 20))
        node.name = "stamp"
        self.addChild(node)
        }
    }
    
    var isFirst = false
    
    func timeCountdown(deltaT: Double) {
        timeToChangeLane -= deltaT
        timeToChangeSpeed -= deltaT
        if cantMoveForXTime > 0 {
            cantMoveForXTime -= deltaT
        }
        if getOutOfTheWay {
            textNode.text = "PRIORITY"
        } else {
            textNode.text = cantMoveForXTime <= 0.0 ? "move":"stop"
        }
        if isFirst {
            textNode.text! += "\n1st"
        }
    }
    
    var roadLanePositions: [Int:CGFloat] {
        get {
            return (self.parent as? GameScene)?.lanePositions ?? [:]
        }
    }
    
    var isMoving = false
    
    var currentLane: Int!
    var cantMoveForXTime = 0.0
    var getOutOfTheWay = false
    var textNode: SKLabelNode!
    
    private var frontSensor: [CGPoint] {
        get {
            return [CGPoint(x: position.x, y: position.y+(size.height/2)+30.0)]
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
    
    private var frontRightSensors: [CGPoint] {
        get {
            let rightDiagUP = CGPoint(x: position.x+(size.width), y: position.y+200)
            let rightDiagC = CGPoint(x: position.x+(size.width), y: position.y+150)
            return [rightDiagUP,rightDiagC]
        }
    }
    
    private var frontLeftSensors: [CGPoint] {
        get {
            let leftDiagUP = CGPoint(x: position.x-(size.width), y: position.y+200)
            let leftDiagC = CGPoint(x: position.x-(size.width), y: position.y+150)
            return [leftDiagUP,leftDiagC]
        }
    }
    
    private var backSensor: [CGPoint] {
        get {
            return [CGPoint(x: position.x, y: position.y-(size.height/2)-100.0)]
        }
    }
    
    private var backRightSensors: [CGPoint] {
        get {
            let rightDiagD = CGPoint(x: position.x+(size.width), y: position.y-200)
            let rightDiagC = CGPoint(x: position.x+(size.width), y: position.y-150)
            return [rightDiagD,rightDiagC]
        }
    }
    
    private var backLeftSensors: [CGPoint] {
        get {
            let leftDiagD = CGPoint(x: position.x-(size.width), y: position.y-200)
            let leftDiagC = CGPoint(x: position.x-(size.width), y: position.y-150)
            return [leftDiagD,leftDiagC]
        }
    }
    
    //!!! sensors change with width! must be static?
    init(withSize size: CGSize, andMindSet mindSet: MVAMindSet, color: UIColor) {
        self.mindSet = mindSet
        super.init(texture: nil, color: color, size: CGSize(width: 60.0, height: 100.0))
        self.textNode = SKLabelNode(text: "0.0")
        self.textNode.fontSize = 20.0
        self.textNode.fontName = UIFont.systemFont(ofSize: 20, weight: 5).fontName
        self.textNode.fontColor = UIColor.white
        self.addChild(self.textNode)
        /*if mindSet == .player {
            for point in rightSensors+leftSensors+frontSensor+backSensor+frontRightSensors+frontLeftSensors+backLeftSensors+backRightSensors {
                let dot = SKSpriteNode(color: .red, size: CGSize(width: 5.0, height: 5.0))
                dot.position = point
                addChild(dot)
            }
        }*/
        
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
    
    func changeLane(inDirection direction: MVAPosition) -> Bool {
        let newLane = direction == .left ? currentLane-1:currentLane+1
        let carsBlockingDirection = self.responseFromSensors(inPositions: [direction])
        let responseFromSensors = self.mindSet == .player ? true:carsBlockingDirection.isEmpty
        if self.roadLanePositions.keys.contains(newLane) && responseFromSensors {
            if let newLaneCoor = roadLanePositions[newLane] {
                self.isMoving = true
                currentLane = newLane
                let endMoving = SKAction.run({
                    self.isMoving = false
                })
                let move = SKAction.moveTo(x: newLaneCoor, duration: 0.25)
                move.timingMode = .easeInEaseOut
                self.run(SKAction.sequence([move,endMoving]))
                return true
            }
        } else if self.roadLanePositions.keys.contains(newLane) && responseFromSensors == false {
            /*carsBlockingDirection = Set(carsBlockingDirection.filter({ $0.mindSet != .player }))
            if let carToMove = carsBlockingDirection.first {
                _ = carToMove.changeLane(inDirection: direction)//!!!
                return false
            }*/
        }
        return false
    }
    
    func mustStayInCurrentLane() -> Set<MVACar>? {
        let frontBlocked = !responseFromSensors(inPositions: [.front]).isEmpty
        if frontBlocked {
            let leftF = responseFromSensors(inPositions: [.frontLeft])
            let left = responseFromSensors(inPositions: [.left])
            let rightF = responseFromSensors(inPositions: [.frontRight])
            let right = responseFromSensors(inPositions: [.right])
            let blockedLeft = !leftF.isEmpty && !left.isEmpty
            let blockedRight = !rightF.isEmpty && !right.isEmpty
            
            if blockedLeft {
                return left.union(leftF)
            } else if blockedRight {
                return right.union(rightF)
            }
        }
        return nil
    }
    
    func responseFromSensors(inPositions positions: [MVAPosition]) -> Set<MVACar> {
        var foundCars = Set<MVACar>()
        for position in positions {
            switch position {
            case .frontLeft: foundCars = foundCars.union(carsIntersecting(sensors: frontLeftSensors))
            case .front: foundCars = foundCars.union(carsIntersecting(sensors: frontSensor))
            case .frontRight: foundCars = foundCars.union(carsIntersecting(sensors: frontRightSensors))
            case .left: foundCars = foundCars.union(carsIntersecting(sensors: leftSensors))
            case .right: foundCars = foundCars.union(carsIntersecting(sensors: rightSensors))
            case .back: foundCars = foundCars.union(carsIntersecting(sensors: frontSensor))
            case .backRight: foundCars = foundCars.union(carsIntersecting(sensors: backRightSensors))
            case .backLeft: foundCars = foundCars.union(carsIntersecting(sensors: backLeftSensors))
            }
        }
        return foundCars
    }
    
    private func carsIntersecting(sensors: [CGPoint]) -> Set<MVACar> {
        var intersectingCars = Set<MVACar>()
        for sensor in sensors {
            if let nodes = parent?.nodes(at: sensor).filter({ $0 is MVACar }) {
                intersectingCars = intersectingCars.union(Set(nodes.map({ $0 as! MVACar }).filter({ $0 != self })))
            }
        }
        return intersectingCars
    }
    
    func changeSpeed(_ speed: CGFloat, durationOfChange duration: CGFloat) {
        if speed != self.pointsPerSecond {
            let oldSpeed = self.pointsPerSecond
            let speedDifference = abs(speed-oldSpeed)
            
            let rateOfSpeedChange = Int(round(speedDifference/duration))
            
            for _ in 0..<rateOfSpeedChange {
                let move = SKAction.moveBy(x: 0.0, y: self.pointsPerSecond, duration: TimeInterval(rateOfSpeedChange))
                self.removeAction(forKey: "move")
                self.run(SKAction.repeatForever(move), withKey: "move")
            }
            self.pointsPerSecond = speed
        }
    }
    
    //????
    func isFreeToMove() -> Bool {
        let front = responseFromSensors(inPositions: [.front,.frontLeft,.frontRight]).isEmpty
        let left = responseFromSensors(inPositions: [.left]).isEmpty
        let right = responseFromSensors(inPositions: [.right]).isEmpty
        return front || left || right
    }
    /*
    func diagonalRight() -> Set<MVACar> {
        var collidingCars = Set<MVACar>()
        for sensor in frontRightSensor {
            if let nodes = parent?.nodes(at: sensor).filter({ $0 is MVACar }) {
                collidingCars = collidingCars.union(Set(nodes.map({ $0 as! MVACar }).filter({ $0 != self })))
            }
        }
        return Set(collidingCars.filter({ $0.mindSet != .player }))
    }
    
    func diagonalLeft() -> Set<MVACar> {
        var collidingCars = Set<MVACar>()
        for sensor in frontLeftSensor {
            if let nodes = parent?.nodes(at: sensor).filter({ $0 is MVACar }) {
                collidingCars = collidingCars.union(Set(nodes.map({ $0 as! MVACar }).filter({ $0 != self })))
            }
        }
        return Set(collidingCars.filter({ $0.mindSet != .player }))
    }*
    
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
    }*/
    
}
