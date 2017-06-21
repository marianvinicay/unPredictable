//
//  PlayerCar.swift
//  (un)Predictable
//
//  Created by Majo on 30/10/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//
//

import SpriteKit

enum MVAPosition: CustomStringConvertible {
    /*
     car = ⍓
     
     FL | F | FR
     –––––––––--
     L  | ⍓ |  R
     -----------
     BL | B | BR
    */
    case frontLeft, front, frontRight
    case right, left
    case back, backLeft, backRight
    
    //DEBUG
    var description: String {
        switch self {
        case .front: return "front"
        case .frontLeft: return "frontLeft"
        case .frontRight: return "frontRight"
        case .right: return "right"
        case .left: return "left"
        case .back: return "back"
        case .backLeft: return "backLeft"
        case .backRight: return "backRight"
        }
    }
}

public class MVACar: SKSpriteNode {
    
    var mindSet: MVAMindSet
    var slowTime = 0.0
    var pointsPerSecond: CGFloat = 0.0
    var timeToRandomise = Double.randomWith2Decimals(inRange: 1..<3)
    
    ///debug func
    func stampIt(withLabel txt: String?) {
        /*if mindSet != .player {
            textNode.text = txt
            textNode.zPosition = 5
        }*/
    }
    
    var isFirst = false
    
    func timeCountdown(deltaT: Double) {
        timeToRandomise -= deltaT
        if cantMoveForTime > 0 {
            cantMoveForTime -= deltaT
        }
        if hasPriority {
            priorityTime -= deltaT
            if priorityTime <= 0 {
                changeSpeed(CGFloat(arc4random_uniform(40)+50))
                hasPriority = false
            }
        }
        if slowTime > 0.0 {
            slowTime -= deltaT
        } else if mindSet == .pseudoPlayer && pointsPerSecond != 220 {
            self.changeSpeed(220)
        }
    }
    
    var roadLanePositions: [Int:CGFloat] {
        get {
            return (self.parent as? GameScene)?.lanePositions ?? [:]
        }
    }
    
    var currentLane: Int!
    var cantMoveForTime = 0.0
    var hasPriority = false
    var priorityTime = 0.0
    var textNode: SKLabelNode!
    var wasChecked = false
    
    private var frontSensor: [CGPoint] {
        get {
            return [CGPoint(x: position.x, y: position.y+size.height*1.5)]
        }
    }
    
    private var rightSensors: [CGPoint] {
        get {
            let topRight = CGPoint(x: position.x+size.width, y: position.y+size.height*1.5)
            let idkRight = CGPoint(x: position.x+size.width, y: position.y+size.height)
            let centerRight = CGPoint(x: position.x+size.width, y: position.y)
            let bottomRight = CGPoint(x: position.x+size.width, y: position.y-size.height)
            return [topRight,idkRight,centerRight,bottomRight]
        }
    }
    
    private var leftSensors: [CGPoint] {
        get {
            let topLeft = CGPoint(x: position.x-size.width, y: position.y+size.height*1.5)
            let idkLeft = CGPoint(x: position.x-size.width, y: position.y+size.height)
            let centerLeft = CGPoint(x: position.x-size.width, y: position.y)
            let bottomLeft = CGPoint(x: position.x-size.width, y: position.y-size.height)
            return [topLeft,idkLeft,centerLeft,bottomLeft]
        }
    }
    
    private var frontRightSensors: [CGPoint] {
        get {
            let rightDiagUP = CGPoint(x: position.x+(size.width), y: position.y+250)
            let rightDiagC = CGPoint(x: position.x+(size.width), y: position.y+150)
            return [rightDiagUP,rightDiagC]
        }
    }
    
    private var frontLeftSensors: [CGPoint] {
        get {
            let leftDiagUP = CGPoint(x: position.x-(size.width), y: position.y+250)
            let leftDiagC = CGPoint(x: position.x-(size.width), y: position.y+150)
            return [leftDiagUP,leftDiagC]
        }
    }
    
    private var backSensor: [CGPoint] {
        get {
            return [CGPoint(x: position.x, y: position.y-size.height)]
        }
    }
    
    private var backRightSensors: [CGPoint] {
        get {
            let rightDiagD = CGPoint(x: position.x+(size.width), y: position.y-250)
            let rightDiagC = CGPoint(x: position.x+(size.width), y: position.y-150)
            return [rightDiagD,rightDiagC]
        }
    }
    
    private var backLeftSensors: [CGPoint] {
        get {
            let leftDiagD = CGPoint(x: position.x-(size.width), y: position.y-250)
            let leftDiagC = CGPoint(x: position.x-(size.width), y: position.y-150)
            return [leftDiagD,leftDiagC]
        }
    }
    
    //!!! sensors change with width! must be static?
    init(withSize size: CGSize, andMindSet mindSet: MVAMindSet, img: String) {
        self.mindSet = mindSet
        super.init(texture: SKTexture(imageNamed: img), color: .clear, size: CGSize(width: 60.0, height: 100.0))
        self.textNode = SKLabelNode(text: "")
        self.textNode.fontSize = 20.0
        self.textNode.fontName = UIFont.systemFont(ofSize: 20, weight: 5).fontName
        self.textNode.fontColor = UIColor.white
        self.addChild(self.textNode)
        //drawSensors()
        
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 60.0, height: 100.0))
        physicsBody?.categoryBitMask = MVAPhysicsCategory.car.rawValue
        physicsBody?.collisionBitMask = MVAPhysicsCategory.car.rawValue
        physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue //| MVAPhysicsCategory.remover.rawValue
        physicsBody?.isDynamic = true
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
    }
    
    func drawSensors() {
        if children.map({ $0.name }).contains(where: { $0 == "dot" }) == false {
            for point in frontSensor/*+leftSensors+rightSensors+backSensor+frontRightSensors+frontLeftSensors+backLeftSensors+backRightSensors*/ {
                let dot = SKSpriteNode(color: .red, size: CGSize(width: 5.0, height: 5.0))
                dot.zPosition = 1.0
                dot.name = "dot"
                dot.position = point
                addChild(dot)
            }
        }
    }
    
    //???
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        return foundCars//Set(foundCars.filter({ $0.mindSet != .player }))
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
    
    func changeLane(inDirection dir: MVAPosition, withPlayer player: MVACar) -> Bool {
        if cantMoveForTime <= 0 {
            let reactionDistance = player.pointsPerSecond*1.8
            let heightDifference = self.mindSet == .player || self.mindSet == .pseudoPlayer ? reactionDistance:abs(player.position.y-self.position.y)//change difficulty !! hasPriority???
            if heightDifference >= reactionDistance {//???
                let newLane = dir == .left ? currentLane-1:currentLane+1
                let carsBlockingDirection = self.responseFromSensors(inPositions: [dir])
                
                let responseFromSensors = self.mindSet == .player ? true:carsBlockingDirection.isEmpty
                if self.roadLanePositions.keys.contains(newLane) && responseFromSensors {
                    if let newLaneCoor = roadLanePositions[newLane] {
                        currentLane = newLane
                        let angle: CGFloat = dir == .left ? 0.3:-0.3
                        let turnIn = SKAction.rotate(toAngle: angle, duration: 0.2)
                        let move = SKAction.moveTo(x: newLaneCoor, duration: 0.25)
                        let turnOut = SKAction.rotate(toAngle: 0.0, duration: 0.2)
                        turnIn.timingMode = .easeInEaseOut
                        move.timingMode = .easeInEaseOut
                        turnOut.timingMode = .easeInEaseOut
                        self.run(SKAction.group([turnIn,move]), completion: {
                            self.run(turnOut)
                        })
                        if mindSet != .player {
                            cantMoveForTime = 1.0
                        }
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func changeSpeed(_ speed: CGFloat) {
        if speed != self.pointsPerSecond {
            self.pointsPerSecond = speed
            self.removeAction(forKey: "move")
            let move = SKAction.moveBy(x: 0.0, y: speed, duration: 1.0)
            self.run(SKAction.repeatForever(move), withKey: "move")
        }
    }
}
