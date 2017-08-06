//
//  PlayerCar.swift
//  (un)Predictable
//
//  Created by Majo on 30/10/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//
//

import SpriteKit

class MVACar: SKSpriteNode {
    var mindSet: MVAMindSet!
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
    var useCounter = 0
    var skin: MVASkin!
    private var brakeLightTime = 0.5
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
        if brakeLightTime > 0 {
            brakeLightTime -= deltaT
            if brakeLightTime <= 0 {
                self.removeChildren(in: self.children.filter({ $0.name == "brake" }))
            }
        }
        
        if cantMoveForTime > 0 {
            cantMoveForTime -= deltaT
        }
        
        if noPriorityForTime > 0 {
            noPriorityForTime -= deltaT
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
    
    class func new(withMindSet mindSet: MVAMindSet, andSkin textures: MVASkin) -> MVACar {
        let carSize = MVAConstants.baseCarSize
        let newCar = MVACar(texture: textures.normal, color: .clear, size: carSize)
        newCar.mindSet = mindSet
        newCar.skin = textures
        /*self.textNode = SKLabelNode(text: "")
        self.textNode.fontSize = 20.0
        self.textNode.fontName = UIFont.systemFont(ofSize: 20, weight: 5).fontName
        self.textNode.fontColor = UIColor.white
        self.addChild(self.textNode)
        drawSensors()*/
        newCar.zPosition = 4.0
        
        newCar.physicsBody = SKPhysicsBody(texture: newCar.skin.normal, size: carSize)
        newCar.physicsBody?.mass = 5
        newCar.physicsBody?.density = 5000.0
        newCar.physicsBody?.friction = 0.0
        newCar.physicsBody?.categoryBitMask = MVAPhysicsCategory.car.rawValue
        newCar.physicsBody?.collisionBitMask = MVAPhysicsCategory.car.rawValue
        newCar.physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue
        newCar.physicsBody?.isDynamic = true
        newCar.physicsBody?.linearDamping = 0.0
        newCar.physicsBody?.angularDamping = 0.2
        newCar.physicsBody?.affectedByGravity = false
        newCar.physicsBody?.allowsRotation = true
        
        return newCar
    }
    
    class func resetPhysicsBody(forCar car: MVACar) {
        car.physicsBody = SKPhysicsBody(texture: car.skin.normal, size: car.size)
        car.physicsBody?.mass = 5
        car.physicsBody?.density = 5000.0
        car.physicsBody?.friction = 0.0
        if car.mindSet == .player {
            car.physicsBody?.categoryBitMask = MVAPhysicsCategory.player.rawValue //???
        } else {
            car.physicsBody?.categoryBitMask = MVAPhysicsCategory.car.rawValue
        }
        car.physicsBody?.collisionBitMask = MVAPhysicsCategory.car.rawValue
        car.physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue
        car.physicsBody?.isDynamic = true
        car.physicsBody?.linearDamping = 0.0
        car.physicsBody?.angularDamping = 0.2
        car.physicsBody?.affectedByGravity = false
        car.physicsBody?.allowsRotation = true
    }
    
    /*func drawSensors() {
        if children.map({ $0.name }).contains(where: { $0 == "dot" }) == false {
            for point in frontSensor+stopSensor {
                let dot = SKSpriteNode(color: .red, size: CGSize(width: 5.0, height: 5.0))
                dot.zPosition = 1.0
                dot.name = "dot"
                dot.position = point
                addChild(dot)
            }
        }
    }*/
    
    func responseFromSensors(inPositions positions: [MVAPosition]) -> Set<MVACar> {
        var foundCars = Set<MVACar>()
        for position in positions {
            switch position {
            case .frontLeft: foundCars = foundCars.union(carsIntersecting(sensors: frontLeftSensors))
            case .front: foundCars = foundCars.union(carsIntersecting(sensors: frontSensor))
            case .frontRight: foundCars = foundCars.union(carsIntersecting(sensors: frontRightSensors))
            case .left: foundCars = foundCars.union(carsIntersecting(sensors: leftSensors))
            case .right: foundCars = foundCars.union(carsIntersecting(sensors: rightSensors))
            case .back: foundCars = foundCars.union(carsIntersecting(sensors: [backSensor]))
            case .backRight: foundCars = foundCars.union(carsIntersecting(sensors: backRightSensors))
            case .backLeft: foundCars = foundCars.union(carsIntersecting(sensors: backLeftSensors))
            case .stop: foundCars = foundCars.union(carsIntersecting(sensors: stopSensor))
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
    
    func changeLane(inDirection dir: MVAPosition, AndPlayer player: MVACar) -> Bool {
        if cantMoveForTime <= 0 {
            let reactionDistance = self.hasPriority ? CGFloat(player.pointsPerSecond):CGFloat(player.pointsPerSecond)*1.3//!!!
            let heightDifference = self.mindSet == .player ? reactionDistance:abs(player.position.y-self.position.y)//change difficulty !! hasPriority???
            let newLane = dir == .left ? currentLane-1:currentLane+1
            if heightDifference >= reactionDistance {
                let carsBlockingDirection = self.responseFromSensors(inPositions: [dir])
                let clearRoadLane = self.mindSet == .player ? true:carsBlockingDirection.isEmpty
            
                if lanePositions[newLane] != nil && clearRoadLane {
                    let newLaneCoor = CGFloat(lanePositions[newLane]!)
                    currentLane = newLane
                    let angle: CGFloat = dir == .left ? 0.5:-0.5
                    var defTurnTime = 0.2
                    if pointsPerSecond > 649 {
                        defTurnTime = 0.15
                    }
                    let turnIn = SKAction.rotate(toAngle: angle, duration: defTurnTime)
                    let move = SKAction.moveTo(x: newLaneCoor, duration: defTurnTime)
                    let turnOut = SKAction.rotate(toAngle: 0.0, duration: defTurnTime)
                    turnIn.timingMode = .easeIn
                    move.timingMode = .linear
                    turnOut.timingMode = .easeOut
                    
                    if dir == .left {
                        leftIndicator()
                    } else {
                        rightIndicator()
                    }
                    self.run(SKAction.sequence([SKAction.group([turnIn,move]),turnOut]), completion: { self.cancelIndicator() })

                    if mindSet == .bot {
                        cantMoveForTime = 1.2
                    }
                    
                    return true
                }
            }
        }
        return false
    }
    
    var newSpeed: Int!
    var speedChange: MVAPosition?
    
    func changeSpeed(_ speed: Int) {
        if speed != pointsPerSecond && speedChange == nil {
            if speed-pointsPerSecond > 0 {
                speedChange = .front
            } else {
                speedChange = .back
                brakeLight(true)
            }
            newSpeed = speed
            smoothSpeedChange()
        }
    }
    
    func smoothSpeedChange() {
        let brakingForce = CGFloat((self.pointsPerSecond/5)*11)
        if speedChange == .front {
            self.physicsBody!.applyForce(CGVector(dx: 0.0, dy: self.physicsBody!.mass*brakingForce))
            if pointsPerSecond < newSpeed {
                self.perform(#selector(smoothSpeedChange), with: nil, afterDelay: 0.01)
            } else {
                speedChange = nil
                newSpeed = nil
            }
        } else if speedChange == .back {
            self.physicsBody!.applyForce(CGVector(dx: 0.0, dy: -self.physicsBody!.mass*brakingForce))
            if pointsPerSecond > newSpeed {
                self.perform(#selector(smoothSpeedChange), with: nil, afterDelay: 0.01)
            } else {
                speedChange = nil
                newSpeed = nil
                brakeLight(false)
            }
        }
    }
    
    private func leftIndicator() {
        DispatchQueue.main.async {
        if self.children.filter({ $0.name == "ind" }).isEmpty {
            let leftNode = SKSpriteNode(texture: self.skin.left)
            leftNode.size = leftNode.size.adjustSize(toNewWidth: self.size.width/2)
            leftNode.anchorPoint = CGPoint(x: 1.0, y: 1.0)
            leftNode.position.y = self.size.height/2
            leftNode.zPosition = 1.0
            leftNode.name = "ind"
            leftNode.alpha = 0.0
            self.addChild(leftNode)
            let tOn = SKAction.run {
                leftNode.alpha = 1.0
            }
            let tOff = SKAction.run {
                leftNode.alpha = 0.0
            }
            let order = SKAction.sequence([tOn,SKAction.wait(forDuration: 0.1),tOff])
            self.run(SKAction.repeatForever(order), withKey: "indic")
        }
        }
    }
    
    private func rightIndicator() {
        DispatchQueue.main.async {
        if self.children.filter({ $0.name == "ind" }).isEmpty {
            let rightNode = SKSpriteNode(texture: self.skin.right)
            rightNode.size = rightNode.size.adjustSize(toNewWidth: self.size.width/2)
            rightNode.anchorPoint = CGPoint(x: 0.0, y: 1.0)
            rightNode.position.y = self.size.height/2
            rightNode.zPosition = 1.0
            rightNode.name = "ind"
            rightNode.alpha = 0.0
            self.addChild(rightNode)
            let tOn = SKAction.run {
                rightNode.alpha = 1.0
            }
            let tOff = SKAction.run {
                rightNode.alpha = 0.0
            }
            let order = SKAction.sequence([tOn,SKAction.wait(forDuration: 0.1),tOff])
            self.run(SKAction.repeatForever(order), withKey: "indic")
        }
        }
    }
    
    private func cancelIndicator() {
        self.removeChildren(in: self.children.filter({ $0.name == "ind" }))
        self.removeAction(forKey: "indic")
    }
    
    func brakeLight(_ flag: Bool) {
        DispatchQueue.main.async {
            if flag {
                if self.children.filter({ $0.name == "brake" }).isEmpty {
                    let brakeNode = SKSpriteNode(texture: self.skin.brake)
                    brakeNode.size = brakeNode.size.adjustSize(toNewWidth: self.size.width)
                    brakeNode.anchorPoint.y = 0.0
                    brakeNode.position.y = -self.size.height/2
                    brakeNode.zPosition = 1.0
                    brakeNode.name = "brake"
                    self.addChild(brakeNode)
                    self.brakeLightTime = 0.5
                }
            } else {
                if self.brakeLightTime <= 0 || self.mindSet == .player {
                    self.removeChildren(in: self.children.filter({ $0.name == "brake" }))
                }
            }
        }
    }
}

extension MVACar {
    // MARK: MVACar's sensors
    fileprivate var frontSensor: [CGPoint] {
        return [CGPoint(x: position.x+size.width/2, y: position.y+size.height*1.6),
                CGPoint(x: position.x-size.width/2, y: position.y+size.height*1.6),
                CGPoint(x: position.x, y: position.y+size.height*1.6)]
    }
    
    fileprivate var stopSensor: [CGPoint] {
        return [CGPoint(x: position.x+size.width/2, y: position.y+(size.height/2)+23),
                CGPoint(x: position.x-size.width/2, y: position.y+(size.height/2)+23),
                CGPoint(x: position.x, y: position.y+(size.height/2)+23)]
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
