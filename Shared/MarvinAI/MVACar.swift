//
//  PlayerCar.swift
//  (un)Predictable
//
//  Created by Majo on 30/10/2016.
//  Copyright © 2016 MarVin. All rights reserved.
//
//

import SpriteKit

enum MVACarNames {
    static let playerOrdinary = "player"
    static let playerLives = "playerJeep"
    static let playerPCS = "audi"
    static let muscle = "car"
    static let classic = "classic"
    static let offRoad = "jeep"
    static let taxi = "taxi"
    static let electric = "tesla"
    static let hybrid = "tesla"
    static let van = "prius"
}

class MVACar: SKSpriteNode {
    
    var pointsPerSecond: Int {
        get {
            return Int(self.physicsBody!.velocity.dy)
        }
        set {
            self.physicsBody!.velocity.dy = CGFloat(newValue)
        }
    }
    
    var brakeLightTime = 0.5
    var currentLane: Int!
    var skin: MVASkin!
    var newSpeed: Int!
    var speedChange: MVAPosition?
    
    func responseFromSensors(inPositions positions: [MVAPosition], withPlayer wPlayer: Bool = false) -> Set<MVACar> {
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
        if wPlayer {
            return foundCars
        } else {
            return Set(foundCars.filter({ $0 is MVACarBot }))
        }
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
    
    func leftIndicator() {
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
    
    func rightIndicator() {
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
    
    func cancelIndicator() {
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
                if self.brakeLightTime <= 0 || self is MVACarPlayer {
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
        let topRight = CGPoint(x: position.x+size.width*1.5, y: position.y+size.height*0.6)
        let centerRight = CGPoint(x: position.x+size.width*1.5, y: position.y)
        let bottomRight = CGPoint(x: position.x+size.width*1.5, y: position.y-size.height/2)
        return [topRight,centerRight,bottomRight]
    }
    
    fileprivate var leftSensors: [CGPoint] {
        let topLeft = CGPoint(x: position.x-size.width*1.5, y: position.y+size.height*0.6)
        let centerLeft = CGPoint(x: position.x-size.width*1.5, y: position.y)
        let bottomLeft = CGPoint(x: position.x-size.width*1.5, y: position.y-size.height/2)
        return [topLeft,centerLeft,bottomLeft]
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
