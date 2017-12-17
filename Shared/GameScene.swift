//
//  GameScene.swift
//  (un)Predictable
//
//  Created by Majo on 25/08/16.
//  Copyright © 2016 MarVin. All rights reserved.
//

import SpriteKit

protocol GameVCDelegate {
    #if os(iOS)
        func present(view: UIViewController, completion: @escaping ()->Void)
    #elseif os(macOS)
        func present(alert: NSAlert, completion: @escaping (NSApplication.ModalResponse)->Void)
    #endif
    func changeControls(to controls: MVAGameControls)
}

enum MVAGameControls {
    case swipe, precise
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Variables
    // MARK: Gameplay Logic
    let intel = MVAMarvinAI()
    var playerDistance = "0.0"
    var gameStarted = false
    var playerBraking = false
    var timesCrashed = 0
    var gameControls: MVAGameControls {
        set {
            MVAMemory.gameControls = newValue
        }
        get {
            return MVAMemory.gameControls
        }
    }
    
    var cDelegate: GameVCDelegate?
    #if os(iOS)
        var lastRotation: Double?
    #elseif os(macOS)
        var lastMousePos: CGFloat?
    #endif
    
    // MARK: Buttons
    var playBtt: SKSpriteNode!
    var pauseBtt: SKSpriteNode!
    var originalPausePosition: CGPoint!
    
    // MARK: Gameplay Sprites
    var speedSign: SKSpriteNode!
    var originalSpeedPosition: CGPoint!
    var distanceSign: SKSpriteNode!
    var originalDistancePosition: CGPoint!
    var recordDistance: SKLabelNode!
    var lives: SKSpriteNode!
    var battery: SKSpriteNode!
    var roadNodes = Set<MVARoadNode>()
    var remover: MVARemoverNode!
    var spawner: MVASpawnerNode!
    
    // MARK: Gameplay Helpers
    var tutorialNode: MVATutorialNode?
    var batteryTime = 0.0
    var lastPressedXPosition: CGFloat!
    var endOfWorld: CGFloat? = 0.0
    var brakingTimer: Timer!
    var lastUpdate: TimeInterval!
    var newBestDisplayed = false
    var canUpdateSpeed = true
    
    // MARK: - Gameplay
    func spawnWithDelay(_ delay: TimeInterval) {
        self.removeAction(forKey: "spawn")
        let spawn = SKAction.run {
            self.spawner.spawnCar(withExistingCars: self.intel.cars.filter({ $0.position.y > self.camera!.position.y+self.size.height/3 }))
        }
        let wait = SKAction.wait(forDuration: delay)
        self.run(SKAction.repeatForever(SKAction.sequence([spawn,wait])), withKey: "spawn")
    }
    
    private func nextLevelSign(withCompletion completion: @escaping (()->())) {
        self.removeAction(forKey: "spawn")
        self.physicsWorld.speed = 0.0
        setLevelSpeed(intel.currentLevel.playerSpeed)
        self.canUpdateSpeed = false
        let rightScale = speedSign.xScale
        let signIN = SKAction.group([SKAction.scale(to: 0.3, duration: 0.4),SKAction.move(to: CGPoint.zero, duration: 0.4)])
        let signOUT = SKAction.group([SKAction.scale(to: rightScale, duration: 0.3),SKAction.move(to: originalSpeedPosition, duration: 0.3)])
        speedSign.run(SKAction.sequence([signIN,SKAction.wait(forDuration: 0.8),signOUT]), completion: {
            self.physicsWorld.speed = 1.0
            self.canUpdateSpeed = true
            completion()
        })
    }
    
    private func displayNewBest() {
        newBestDisplayed = true
        let downY: CGFloat = MVAMemory.isIphoneX ? 33.0:0.0
        let label = SKLabelNode(fontNamed: "Futura Bold")
        label.fontSize = 20
        label.text = "New Best!"
        label.verticalAlignmentMode = .bottom
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: distanceSign.position.x+distanceSign.size.width+3, y: (-self.size.height/2)+label.frame.height+downY)
        label.zPosition = 7.0
        label.name = "nBest"
        let addAct = SKAction.run {
            label.yScale = 0.0
            self.camera!.addChild(label)
            label.run(SKAction.scaleY(to: 1.0, duration: 0.5))
        }
        let removeAct = SKAction.run {
            label.run(SKAction.scaleY(to: 0.0, duration: 0.5)) {
                label.removeFromParent()
            }
        }
        self.camera!.run(SKAction.sequence([addAct,SKAction.wait(forDuration: 5.0),removeAct]))
    }
    
    private func updateCamera() {
        spawner.position.y = camera!.position.y+self.size.height
        if intel.player != nil {
            let desiredCameraPosition = intel.player.position.y+size.height/4
            camera!.run(SKAction.moveTo(y: desiredCameraPosition, duration: 0.04))
            //camera!.position.y = desiredCameraPosition
        }
        remover.position.y = camera!.position.y-self.size.height
    }

    private func showPCSWarning() {
        if camera?.childNode(withName: "pcs") == nil {
            let pcs = SKSpriteNode(imageNamed: "pcs")
            pcs.name = "pcs"
            pcs.size = self.size
            pcs.position = .zero
            pcs.zPosition = 7.0
            camera!.addChild(pcs)
            pcs.run(SKAction.fadeOut(withDuration: 2.2)) {
                pcs.removeFromParent()
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        updateCamera()
        if gameStarted {
            if lastUpdate != nil {
                let dTime = currentTime-lastUpdate
                intel.update(withDeltaTime: dTime)
                
                if intel.player.pcsActive && !playerBraking {
                    if intel.checkPCS(withDeltaTime: dTime) {
                        showPCSWarning()
                        removeLife()
                    }
                }
                
                if batteryTime > 0 {
                    batteryTime -= dTime
                }
            }
            lastUpdate = currentTime

            DispatchQueue.main.async {
                if self.intel.player.pcsActive && self.batteryTime <= 0 && self.intel.playerLives < 3 {
                    self.addToBattery()
                }
                
                let newDistance = MVAWorldConverter.distanceToOdometer(self.intel.distanceTraveled)
                if self.playerDistance != newDistance {
                    if !self.newBestDisplayed && MVAMemory.maxPlayerDistance != 0.0 && MVAMemory.maxPlayerDistance <= self.intel.distanceTraveled {
                        self.displayNewBest()
                    }
                    self.playerDistance = newDistance
                    self.setDistance(newDistance)
                    
                    if newDistance == MVAWorldConverter.distanceToOdometer(Double(self.intel.currentLevel.nextMilestone)) && !self.playerBraking {
                        self.intel.currentLevel.level += 1
                        self.nextLevelSign() {
                            if !self.playerBraking {
                                self.intel.player.changeSpeed(self.intel.currentLevel.playerSpeed)
                            }
                            self.spawnWithDelay(self.intel.currentLevel.spawnRate)
                        }
                    }
                }
            }
            
            if endOfWorld != nil {
                if MVAMemory.tutorialDisplayed && endOfWorld! < self.camera!.position.y {
                    let road = MVARoadNode.createWith(texture: spawner.roadTexture, height: self.size.height, andWidth: self.size.width)
                    road.position = .zero
                    road.name = "road"
                    camera!.addChild(road)
                    endOfWorld = nil
                    roadNodes.forEach({
                        $0.removeFromParent()
                        roadNodes.remove($0)
                    })
                } else if MVAMemory.tutorialDisplayed == false && endOfWorld!-self.size.height < self.camera!.position.y {
                    let road = MVARoadNode.createWith(texture: SKTexture(imageNamed: "Start2"), height: self.size.height, andWidth: self.size.width)
                    road.position = CGPoint(x: 0.0, y: endOfWorld!)
                    road.name = "road"
                    endOfWorld = road.position.y+road.size.height
                    roadNodes.insert(road)
                    self.addChild(road)
                }
            }
        }
    }
    
    func endTutorial() {
        let tutorialEnding = { () in
            self.tutorialNode?.removeFromParent()
            self.tutorialNode = nil
            self.intel.updateDist = true
            self.showHUD()
            
            MVAMemory.tutorialDisplayed = true
            
            let road = MVARoadNode.createWith(texture: self.spawner.roadTexture, height: self.size.height, andWidth: self.size.width)
            road.position = CGPoint(x: 0.0, y: self.endOfWorld!)
            road.name = "road"
            self.roadNodes.insert(road)
            self.addChild(road)
            
            if MVAMemory.enableGameCenter {
                self.intel.gameCHelper.authenticateLocalPlayer() { (granted: Bool) in
                    #if os(iOS) || os(tvOS)
                        if let myVC = UIApplication.shared.keyWindow?.rootViewController as? GameViewController {
                            if granted {
                                myVC.gameCenterBtt.isHidden = false
                            } else {
                                myVC.gameCenterBtt.isHidden = true
                            }
                        }
                    #elseif os(macOS)
                        if let myVC = NSApplication.shared.mainWindow?.contentViewController as? GameViewControllerMAC {
                            if granted {
                                myVC.gameCenterBtt.isHidden = false
                            } else {
                                myVC.gameCenterBtt.isHidden = true
                            }
                        }
                    #endif
                }
            }
        }
        
        #if os(iOS)
            let dialog = MVAPopup.create(withTitle: "What do you prefer?", andMessage: nil)
            let mManager = (UIApplication.shared.delegate as! AppDelegate).motionManager
            
            MVAPopup.addAction(toPopup: dialog, withTitle: "Swipe") {
                self.tutorialNode?.end(tutorialEnding)
                self.cDelegate?.changeControls(to: .swipe)
                self.physicsWorld.speed = 1.0
                self.intel.stop = false
                self.intel.player.run(SKAction.moveTo(x: CGFloat(lanePositions[self.intel.player.currentLane] ?? 0), duration: 0.2))
            }
            if mManager.isDeviceMotionAvailable {
                MVAPopup.addAction(toPopup: dialog, withTitle: "Tilt") {
                    self.tutorialNode?.end(tutorialEnding)
                    self.cDelegate?.changeControls(to: .precise)
                    self.physicsWorld.speed = 1.0
                    self.intel.stop = false
                }
            }
        #elseif os(macOS)
            let dialog = MVAPopup.create(withTitle: "What controls do you prefer?", andMessage: nil)
            MVAPopup.addAction(toPopup: dialog, withTitle: "Arrows")
            MVAPopup.addAction(toPopup: dialog, withTitle: "Mouse", shouldHighlight: true)
        #endif
        
        self.run(SKAction.sequence([
            SKAction.run({ self.tutorialNode?.prepareEnd() }),
            SKAction.wait(forDuration: 0.8),
            SKAction.run({
                self.handleBrake(started: false)
                self.physicsWorld.speed = 0.0
                self.intel.stop = true
                #if os(iOS)
                    self.cDelegate?.present(view: dialog, completion: {})
                #elseif os(macOS)
                    //NSCursor.unhide()
                    self.cDelegate?.present(alert: dialog) { (resp: NSApplication.ModalResponse) in
                        switch resp {
                        case .alertFirstButtonReturn:
                            self.tutorialNode?.end(tutorialEnding)
                            self.cDelegate?.changeControls(to: .swipe)
                            self.physicsWorld.speed = 1.0
                            self.intel.stop = false
                            self.intel.player.run(SKAction.moveTo(x: CGFloat(lanePositions[self.intel.player.currentLane] ?? 0), duration: 0.2))
                        case .alertSecondButtonReturn:
                            self.tutorialNode?.end(tutorialEnding)
                            self.cDelegate?.changeControls(to: .precise)
                            self.physicsWorld.speed = 1.0
                            self.intel.stop = false
                            //NSCursor.hide()
                        default: break
                        }
                    }
                #endif
            })]))
    }
    
    // MARK: - Controls
    func handleSwipe(swipe: MVAPosition) {
        if gameStarted && physicsWorld.speed != 0.0 {
            if intel.player.changeLane(inDirection: swipe) {
                intel.sound.indicate(onNode: intel.player)
                
                if tutorialNode?.stage == 0 {
                    tutorialNode!.continueToTilting(playerCar: self.intel.player)
                }
            }
        }
    }
    
    func handleBrake(started: Bool) {
        if gameStarted {
            guard tutorialNode == nil || (tutorialNode?.stage ?? 0) > 2 else { return }
            
            if started {
                if playerBraking == false {
                    self.removeAction(forKey: "spawn")
                    spawner.size.height = self.size.height
                    playerBraking = true
                    intel.player.brakeLight(true)
                    
                    if self.tutorialNode?.stage == 3 {
                        endTutorial()
                    }
                }
                deceleratePlayer()
            } else {
                if playerBraking == true {
                    playerBraking = false
                    spawnWithDelay(intel.currentLevel.spawnRate)
                    intel.player.brakeLight(false)
                }
                acceleratePlayer()
            }
        }
    }
    
    func handlePreciseMove(withDeltaX deltaX: CGFloat, animated anim: Bool = false) {
        if gameStarted && physicsWorld.speed != 0.0 && (tutorialNode == nil || tutorialNode?.stage != 0) {
            let newPlayerPos = self.intel.player.position.x + deltaX
            if newPlayerPos >= CGFloat(lanePositions[0]!)-intel.player.size.width/1.2 &&
                newPlayerPos <= CGFloat(lanePositions[lanePositions.keys.max()!]!)+intel.player.size.width/1.2 {
                if anim {
                    intel.player.run(SKAction.moveTo(x: newPlayerPos, duration: 0.1))
                } else {
                    intel.player.position.x = newPlayerPos
                }
                
                let closestLane = lanePositions.enumerated().min(by: { abs(CGFloat($0.element.value) - newPlayerPos) < abs(CGFloat($1.element.value) - newPlayerPos) })!
                intel.player.currentLane = closestLane.element.key
                
                if tutorialNode?.stage == 2 {
                    tutorialNode?.continueToBraking()
                }
            }
        }
    }
    
    @objc func acceleratePlayer() {
        if playerBraking == false {
            if intel.player.pointsPerSecond < intel.currentLevel.playerSpeed {
                let forForce = CGFloat((intel.currentLevel.playerSpeed/5)*9)
                intel.player.physicsBody!.applyForce(CGVector(dx: 0.0, dy: intel.player.physicsBody!.mass*forForce))
                if intel.player.pointsPerSecond > 150 {
                    setLevelSpeed(intel.player.pointsPerSecond)
                }
                if self.audioEngine.mainMixerNode.outputVolume < 1.0 {
                    setVolume(audioEngine.mainMixerNode.outputVolume+0.1)
                }
                self.perform(#selector(acceleratePlayer), with: nil, afterDelay: 0.01)
            } else {
                intel.player.pointsPerSecond = intel.currentLevel.playerSpeed
                setLevelSpeed(intel.currentLevel.playerSpeed)
                spawner.size.height = MVAConstants.baseCarSize.height*2.5
                setVolume(1.0)
            }
        }
    }
    
    @objc func deceleratePlayer() {
        if playerBraking {
            var minSpeed = 150
            if let carInFront = intel.player.responseFromSensors(inPositions: [.front, .stop]).first {
                if carInFront.pointsPerSecond > 1 && carInFront.pointsPerSecond < 111 {
                    minSpeed = carInFront.pointsPerSecond
                }
            }

            if intel.player.pointsPerSecond > minSpeed {
                let backForce = intel.currentLevel.level > 6 ? CGFloat((intel.currentLevel.playerSpeed/5)*13)*1.8 : CGFloat((intel.currentLevel.playerSpeed/5)*13)
                intel.player.physicsBody!.applyForce(CGVector(dx: 0.0, dy: -intel.player.physicsBody!.mass*backForce))

                setLevelSpeed(intel.player.pointsPerSecond)
                
                if self.audioEngine.mainMixerNode.outputVolume > 0.4 {
                    setVolume(audioEngine.mainMixerNode.outputVolume-0.1)
                }
            } else {
                setLevelSpeed(150)
            }
            self.perform(#selector(deceleratePlayer), with: nil, afterDelay: 0.01)
        }
    }
    
    func touchedPosition(_ pos: CGPoint) {
        if !gameStarted && playBtt.contains(pos) {
            self.isUserInteractionEnabled = false
            self.startGame()
        } else if gameStarted && pauseBtt.contains(pos) {
            pauseGame(withAnimation: true)
        } else if gameStarted && playBtt.contains(pos) {
            resumeGame()
        }
    }
    
    // MARK: - SKPhysicsContactDelegate
    private var playerInCollision = false
    
    @objc func cancelPlayerCollision() { playerInCollision = false }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        switch collision {
        case MVAPhysicsCategory.car.rawValue | MVAPhysicsCategory.remover.rawValue:
            if let node = contact.bodyA.node as? MVACarBot {
                scrape(car: node)
            } else if let node = contact.bodyB.node as? MVACarBot {
                scrape(car: node)
            }
        case MVAPhysicsCategory.car.rawValue | MVAPhysicsCategory.car.rawValue:
            if let node1 = contact.bodyA.node as? MVACarBot,
                let node2 = contact.bodyB.node as? MVACarBot {
                let maxYFrame = self.camera!.position.y+self.size.height/2+MVAConstants.baseCarSize.height
                let minYFrame = self.camera!.position.y-self.size.height/2-MVAConstants.baseCarSize.height
                if maxYFrame > contact.contactPoint.y && contact.contactPoint.y > minYFrame {
                    for car in [node1,node2] {
                        car.pointsPerSecond = 0
                        car.removeAllActions()
                        car.removeAllChildren()
                        car.physicsBody!.isDynamic = false
                    }
                    intel.sound.crash(onNode: node1)
                    generateSmoke(atPoint: contact.contactPoint, forTime: 25.0)
                } else {
                    for car in [node1,node2] {
                        scrape(car: car)
                    }
                }
            }
        case MVAPhysicsCategory.car.rawValue | MVAPhysicsCategory.player.rawValue:
            if !playerInCollision {
                playerInCollision = true
                if intel.player.skin.name == MVACarNames.playerLives && intel.playerLives > 0 {
                    removeLife()
                    intel.sound.crash(onNode: intel.player)
                    let ordCar = [contact.bodyA.node, contact.bodyB.node].map({ $0 as? MVACarBot })
                    for car in ordCar {
                        if car != nil { delete(car: car!) }
                    }
                    intel.player.resetPhysicsBody()
                    intel.player.pointsPerSecond = intel.currentLevel.playerSpeed
                } else {
                    physicsWorld.speed = 0.0
                    intel.stop = true
                    intel.player.pointsPerSecond = 0
                    intel.player.removeAllActions()
                    intel.player.removeAllChildren()
                    intel.cars.forEach({
                        $0.removeAllActions()
                        $0.removeAllChildren()
                        $0.pointsPerSecond = 0
                    })
                    intel.sound.crash(onNode: intel.player)
                    generateSmoke(atPoint: contact.contactPoint, forTime: nil)
                    hideHUD(animated: true)
                    self.camera!.childNode(withName: "nBest")?.removeFromParent()
                    gameOver()
                }
                perform(#selector(cancelPlayerCollision), with: nil, afterDelay: 0.05)
            }
        default: break
        }
    }
    
    private func generateSmoke(atPoint point: CGPoint, forTime time: TimeInterval?) {
        let particles = SKEmitterNode(fileNamed: "MVAParticle")
        particles?.position = point
        particles?.name = "smoke"
        particles?.zPosition = 5.5
        self.addChild(particles!)
        let remSmoke = SKAction.run {
            particles?.removeFromParent()
        }
        if time != nil {
            self.run(SKAction.sequence([SKAction.wait(forDuration: time!),remSmoke]))
        }
    }
    
    private func delete(car: MVACarBot) {
        car.physicsBody = nil
        car.run(SKAction.scale(to: 0.0, duration: 0.1)) {
            car.removeFromParent()
        }
        intel.cars.remove(car)
    }
    
    private func scrape(car: MVACarBot) {
        car.pointsPerSecond = 0
        car.removeFromParent()
        intel.cars.remove(car)
        spawner.usedCars.insert(car)
    }
}

