//
//  MVACarPlayer.swift
//  unPredictable
//
//  Created by Majo on 18/08/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

class MVACarPlayer: MVACar {
    
    var pcsActive: Bool {
        get {
            return skin.name == MVACarNames.playerPCS
        }
    }
    var pcsProcessing = false
    
    class func new(withSkin textures: MVASkin) -> MVACarPlayer {
        let carSize = MVAConstants.baseCarSize
        let newCar = MVACarPlayer(texture: textures.normal, color: .clear, size: carSize)
        newCar.skin = textures
        newCar.zPosition = 4.0
        
        newCar.physicsBody = SKPhysicsBody(texture: newCar.skin.normal, size: carSize)
        newCar.physicsBody?.mass = 5
        newCar.physicsBody?.density = 5000.0
        newCar.physicsBody?.friction = 0.0
        newCar.physicsBody?.categoryBitMask = MVAPhysicsCategory.player.rawValue
        newCar.physicsBody?.collisionBitMask = MVAPhysicsCategory.car.rawValue
        newCar.physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue
        newCar.physicsBody?.isDynamic = true
        newCar.physicsBody?.linearDamping = 0.0
        newCar.physicsBody?.angularDamping = 0.2
        newCar.physicsBody?.affectedByGravity = false
        newCar.physicsBody?.allowsRotation = true
        
        return newCar
    }
    
    func resetPhysicsBody() {
        physicsBody = SKPhysicsBody(texture: skin.normal, size: size)
        physicsBody?.mass = 5
        physicsBody?.density = 5000.0
        physicsBody?.friction = 0.0
        physicsBody?.categoryBitMask = MVAPhysicsCategory.player.rawValue
        physicsBody?.collisionBitMask = MVAPhysicsCategory.car.rawValue
        physicsBody?.contactTestBitMask = MVAPhysicsCategory.car.rawValue
        physicsBody?.isDynamic = true
        physicsBody?.linearDamping = 0.0
        physicsBody?.angularDamping = 0.2
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = true
    }
    
    func changeLane(inDirection dir: MVAPosition, pcsCalling pcsCall: Bool = false) -> Bool {
        if !pcsProcessing {
            let newLane = dir == .left ? currentLane-1:currentLane+1
            var carsBlockingDirection = Set<MVACar>()
            if pcsCall {
                pcsProcessing = true
                carsBlockingDirection = self.responseFromSensors(inPositions: [dir])
            }
            
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
                self.run(SKAction.sequence([SKAction.group([turnIn,move]),turnOut]), completion: {
                    self.cancelIndicator()
                    self.pcsProcessing = false
                })
                
                return true
            }
        }
        return false
    }
}
