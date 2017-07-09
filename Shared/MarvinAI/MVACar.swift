//
//  PlayerCar.swift
//  (un)Predictable
//
//  Created by Majo on 30/10/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//
//

import SpriteKit

public class MVACar: SKSpriteNode {
    
    var mindSet: MVAMindSet
    var pointsPerSecond: Int {
        get {
            return Int(self.physicsBody!.velocity.dy)
        }
        set {
            self.physicsBody!.velocity.dy = CGFloat(newValue)
        }
    }
    var timeToRandomise = Double.randomWith2Decimals(inRange: 1..<3)
    var currentLane: Int!
    var cantMoveForTime = 0.0
    var hasPriority = false
    var priorityTime = 0.0
    //var textNode: SKLabelNode!
    
    var noPriorityForTime = 0.0
    
    ///debug func
    /*func stampIt(withLabel txt: String?) {
        if mindSet != .player {
            textNode.text = txt
            textNode.zPosition = 5
        }
    }*/
    
    func timeCountdown(deltaT: Double) {
        timeToRandomise -= deltaT
        if cantMoveForTime > 0 {
            cantMoveForTime -= deltaT
        }
        
        if noPriorityForTime > 0 {
            noPriorityForTime -= deltaT
        }

        if changingSpeed {
            smoothSpeedChange()
        }
        
        if hasPriority {
            priorityTime -= deltaT
            if priorityTime <= 0 {
                changeSpeed(MVAConstants.baseBotSpeed)
                noPriorityForTime = 1.0
                hasPriority = false
            }
        }
    }
    
    //!!! sensors change with width! must be static?
    init(withMindSet mindSet: MVAMindSet, andSkin img: String) {
        self.mindSet = mindSet
        var carSize = MVAConstants.baseCarSize
        super.init(texture: SKTexture(imageNamed: img), color: .clear, size: carSize)
        /*self.textNode = SKLabelNode(text: "")
        self.textNode.fontSize = 20.0
        self.textNode.fontName = UIFont.systemFont(ofSize: 20, weight: 5).fontName
        self.textNode.fontColor = UIColor.white
        self.addChild(self.textNode)
        drawSensors()*/
        
        carSize.height = 90
        carSize.width = 50
        
        physicsBody = SKPhysicsBody(rectangleOf: carSize)
        physicsBody?.mass = 2000
        physicsBody?.density = 0
        physicsBody?.categoryBitMask = MVAPhysicsCategory.car.rawValue
        physicsBody?.collisionBitMask = MVAPhysicsCategory.car.rawValue
        physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue //| MVAPhysicsCategory.remover.rawValue
        physicsBody?.isDynamic = true
        physicsBody?.linearDamping = 0.0
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
    }
    
    /*func drawSensors() {
        if children.map({ $0.name }).contains(where: { $0 == "dot" }) == false {
            for point in frontSensor+leftSensors+rightSensors+backSensor+frontRightSensors+frontLeftSensors+backLeftSensors+backRightSensors {
                let dot = SKSpriteNode(color: .red, size: CGSize(width: 5.0, height: 5.0))
                dot.zPosition = 1.0
                dot.name = "dot"
                dot.position = point
                addChild(dot)
            }
        }
    }*/
    
    //???
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func responseFromSensors(inPositions positions: [MVAPosition]) -> Set<MVACar> {
        var foundCars = Set<MVACar>()
        for position in positions {
            switch position {
            case .frontLeft: foundCars = foundCars.union(carsIntersecting(sensors: frontLeftSensors))
            case .front: foundCars = foundCars.union(carsIntersecting(sensors: [frontSensor]))
            case .frontRight: foundCars = foundCars.union(carsIntersecting(sensors: frontRightSensors))
            case .left: foundCars = foundCars.union(carsIntersecting(sensors: leftSensors))
            case .right: foundCars = foundCars.union(carsIntersecting(sensors: rightSensors))
            case .back: foundCars = foundCars.union(carsIntersecting(sensors: [backSensor]))
            case .backRight: foundCars = foundCars.union(carsIntersecting(sensors: backRightSensors))
            case .backLeft: foundCars = foundCars.union(carsIntersecting(sensors: backLeftSensors))
            case .stop: foundCars = foundCars.union(carsIntersecting(sensors: [stopSensor]))
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
    
    func changeLane(inDirection dir: MVAPosition, withLanePositions roadLanePositions: [Int:CGFloat], AndPlayer player: MVACar) -> Bool {
        if cantMoveForTime <= 0 {
            let reactionDistance = self.hasPriority ? CGFloat(player.pointsPerSecond)*0.6:CGFloat(player.pointsPerSecond)*1.6
            let heightDifference = self.mindSet == .player ? reactionDistance:abs(player.position.y-self.position.y)//change difficulty !! hasPriority???
            let newLane = dir == .left ? currentLane-1:currentLane+1
            if /*newLane != player.currentLane ||*/ heightDifference >= reactionDistance {//???
                let newLaneCoor = roadLanePositions[newLane]
                let carsBlockingDirection = self.responseFromSensors(inPositions: [dir])
                let responseFromSensors = self.mindSet == .player ? true:carsBlockingDirection.isEmpty
            
                if newLaneCoor != nil && responseFromSensors {
                    currentLane = newLane
                    let angle: CGFloat = dir == .left ? 0.5:-0.5
                    let turnIn = SKAction.rotate(toAngle: angle, duration: 0.2)
                    let move = SKAction.moveTo(x: newLaneCoor!, duration: 0.2)
                    let turnOut = SKAction.rotate(toAngle: 0.0, duration: 0.2)
                    turnIn.timingMode = .easeIn
                    move.timingMode = .linear
                    turnOut.timingMode = .easeOut
                    self.run(SKAction.sequence([SKAction.group([turnIn,move]),turnOut]))

                    if mindSet == .bot {
                        cantMoveForTime = 1.2
                    }
                    
                    return true
                }
            }
        }
        return false
    }
    
    var changingSpeed = false
    var newSpeedDiff = 0
    
    func changeSpeed(_ speed: Int) {
        if speed != pointsPerSecond {
            if changingSpeed == false {
                changingSpeed = true
                newSpeedDiff = speed-pointsPerSecond
            }
            smoothSpeedChange()
        }
    }
    
    func smoothSpeedChange() {
        if newSpeedDiff > 0 {
            pointsPerSecond += 5
            newSpeedDiff -= 5
        } else if newSpeedDiff < 0 {
            pointsPerSecond -= 5
            newSpeedDiff += 5
        } else {
            print("endChange")
            changingSpeed = false
        }
    }
}

extension MVACar {
    // MARK: MVACar's sensors
    fileprivate var frontSensor: CGPoint {
        return CGPoint(x: position.x, y: position.y+size.height*1.6)
    }
    
    fileprivate var stopSensor: CGPoint {
        return CGPoint(x: position.x, y: position.y+size.height+10)
    }
    
    fileprivate var rightSensors: [CGPoint] {
        let topRight = CGPoint(x: position.x+size.width*1.5, y: position.y+size.height*1.5)
        let idkRight = CGPoint(x: position.x+size.width*1.5, y: position.y+size.height)
        let centerRight = CGPoint(x: position.x+size.width*1.5, y: position.y)
        let bottomRight = CGPoint(x: position.x+size.width*1.5, y: position.y-size.height)
        return [topRight,idkRight,centerRight,bottomRight]
    }
    
    fileprivate var leftSensors: [CGPoint] {
        let topLeft = CGPoint(x: position.x-size.width*1.5, y: position.y+size.height*1.5)
        let idkLeft = CGPoint(x: position.x-size.width*1.5, y: position.y+size.height)
        let centerLeft = CGPoint(x: position.x-size.width*1.5, y: position.y)
        let bottomLeft = CGPoint(x: position.x-size.width*1.5, y: position.y-size.height)
        return [topLeft,idkLeft,centerLeft,bottomLeft]
    }
    
    fileprivate var frontRightSensors: [CGPoint] {
        let rightDiagUP = CGPoint(x: position.x+(size.width*1.5), y: position.y+(size.height*2.5))//250)
        let rightDiagC = CGPoint(x: position.x+(size.width*1.5), y: position.y+(size.height*1.5))//150)
        return [rightDiagUP,rightDiagC]
    }
    
    fileprivate var frontLeftSensors: [CGPoint] {
        let leftDiagUP = CGPoint(x: position.x-(size.width*1.5), y: position.y+(size.height*2.5))
        let leftDiagC = CGPoint(x: position.x-(size.width*1.5), y: position.y+(size.height*1.5))
        return [leftDiagUP,leftDiagC]
    }
    
    fileprivate var backSensor: CGPoint {
        return CGPoint(x: position.x, y: position.y-size.height*1.5)
    }
    
    fileprivate var backRightSensors: [CGPoint] {
        let rightDiagD = CGPoint(x: position.x+(size.width*1.5), y: position.y-(size.height*2.5))
        let rightDiagC = CGPoint(x: position.x+(size.width*1.5), y: position.y-(size.height*1.5))
        return [rightDiagD,rightDiagC]
    }
    
    fileprivate var backLeftSensors: [CGPoint] {
        let leftDiagD = CGPoint(x: position.x-(size.width*1.5), y: position.y-(size.height*2.5))
        let leftDiagC = CGPoint(x: position.x-(size.width*1.5), y: position.y-(size.height*1.5))
        return [leftDiagD,leftDiagC]
    }
}
