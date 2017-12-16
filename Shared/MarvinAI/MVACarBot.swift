//
//  MVACarBot.swift
//  unPredictable
//
//  Created by Majo on 18/08/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

class MVACarBot: MVACar {
    
    var timeToRandomise = Double.randomWith2Decimals(inRange: 1..<3)
    var cantMoveForTime = 0.0
    
    var hasPriority = false
    var priorityTime = 0.0
    var noPriorityForTime = 0.0
    
    var useCounter = 0
    
    class func new(withSkin textures: MVASkin) -> MVACarBot {
        let carSize = MVAConstants.baseCarSize
        let newCar = MVACarBot(texture: textures.normal, color: .clear, size: carSize)
        newCar.skin = textures
        newCar.zPosition = 4.0
        
        newCar.physicsBody = SKPhysicsBody(texture: newCar.skin.normal, size: CGSize(width: carSize.width-6, height: carSize.height-6))
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
    
    func changeLane(inDirection dir: MVAPosition, AndPlayer player: MVACar) -> Bool {
        if cantMoveForTime <= 0 {
            let reactionDistance = self.hasPriority ? CGFloat(player.pointsPerSecond):CGFloat(player.pointsPerSecond)*1.3// !!!
            let heightDifference = abs(player.position.y-self.position.y) //changes difficulty
            
            let newLane = dir == .left ? currentLane-1:currentLane+1
            if heightDifference >= reactionDistance {
                let carsBlockingDirection = self.responseFromSensors(inPositions: [dir], withPlayer: true)
                
                if lanePositions[newLane] != nil && carsBlockingDirection.isEmpty {
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
                    
                    cantMoveForTime = 1.2
                    
                    return true
                }
            }
        }
        return false
    }
}
