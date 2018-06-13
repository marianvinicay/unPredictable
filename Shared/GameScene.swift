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
    #else
        func present(alert: NSAlert, completion: @escaping (NSApplication.ModalResponse)->Void)
        func distanceChanged(toNumberString numStr: String?)
        func showInInfoLabel(_ txt: String, forDuration time: TimeInterval)
    #endif
    func changeControls(to controls: MVAGameControls)
}

enum MVAGameControls: String {
    case swipe = "sw", precise = "p", sphero = "sp"
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Variables
    // MARK: Gameplay Logic
    let intel = MVAMarvinAI()
    var playerDistance = "0.0"
    var gameStarted = false
    var playerBraking: Bool {
        get {
            return intel.playerBraking
        }
        set {
            intel.playerBraking = newValue
        }
    } //= false
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
        var lastAngle: Double?
        //var sphero: RKConvenienceRobot?
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
            //self.lastAngle = nil //????
            self.physicsWorld.speed = 1.0
            self.canUpdateSpeed = true
            completion()
        })
    }
    
    private func displayNewBest() {
        newBestDisplayed = true
        let label = SKLabelNode(fontNamed: "Futura Bold")
        label.fontColor = .white
        label.fontSize = 20
        label.text = "New Best!"
        label.verticalAlignmentMode = .bottom
        label.horizontalAlignmentMode = .left
        let shape = SKShapeNode(rectOf: CGSize(width: label.frame.size.width*1.3, height: label.frame.size.height*2))
        shape.fillColor = .black
        shape.strokeColor = .black
        shape.zPosition = 6.0
        shape.name = "nBest"
        shape.addChild(label)
        label.position = CGPoint(x: -shape.frame.size.width/2.6, y: -shape.frame.size.height/4)
        shape.position = CGPoint(x: shape.frame.size.width/2+distanceSign.position.x-2, y: shape.frame.size.height/2+distanceSign.frame.maxY-2)
        label.zPosition = 1.0
        let addAct = SKAction.run {
            shape.xScale = 0.0
            self.camera!.addChild(shape)
            shape.run(SKAction.scaleX(to: 1.0, duration: 0.5))
        }
        let removeAct = SKAction.run {
            shape.run(SKAction.scaleX(to: 0.0, duration: 0.5)) {
                shape.removeFromParent()
            }
        }
        self.camera!.run(SKAction.sequence([addAct,SKAction.wait(forDuration: 5.0),removeAct]))
        #if os(macOS)
        self.cDelegate?.showInInfoLabel("New Best!", forDuration: 5.0)
        #endif
    }
    
    private func updateCamera() {
        let desiredCameraPosition = intel.player.position.y+size.height/4
        spawner.position.y = desiredCameraPosition+self.size.height
        if intel.player != nil {
            camera!.run(SKAction.moveTo(y: desiredCameraPosition, duration: 0.04))
            //camera!.position.y = desiredCameraPosition
        }
        remover.position.y = desiredCameraPosition-self.size.height
    }

    private func showPCSWarning() {
        if camera?.childNode(withName: "pcs") == nil {
            let pcs = SKSpriteNode(imageNamed: "pcs")
            pcs.name = "pcs"
            pcs.size = self.size
            pcs.position = .zero
            pcs.zPosition = 7.0
            camera!.addChild(pcs)
            #if os(iOS)
            if gameControls != .sphero {
                let vibrator = UIImpactFeedbackGenerator(style: .medium)
                vibrator.impactOccurred()
            } else {
                blinkSphero(withTime: 1.8, andColor: (r: 0.98, g: 0.53, b: 0.20))
            }
            #else
            self.cDelegate?.showInInfoLabel("⚠️ ⚠️ ⚠️", forDuration: 1.8)
            #endif
            pcs.run(SKAction.fadeOut(withDuration: 1.9)) {
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
                
                if turnPCS > 0 {
                    turnPCS -= dTime
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
            
            if self.gameControls != .sphero {
                MVAMemory.tutorialDisplayed = true
            } else {
                MVAMemory.spheroTutorialDisplayed = true
            }
            
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
        
        let continueWithControls = { (type: MVAGameControls) in
            self.tutorialNode?.end(tutorialEnding)
            self.cDelegate?.changeControls(to: type)
            self.physicsWorld.speed = 1.0
            self.intel.stop = false
        }
        
        if self.gameControls != .sphero {
            #if os(iOS)
            var dialog = MVAPopup.create(withTitle: "What do you prefer?", andMessage: nil)
            let mManager = (UIApplication.shared.delegate as! AppDelegate).motionManager
            
            let continueWithSwipe = {
                continueWithControls(.swipe)
                self.intel.player.run(SKAction.moveTo(x: CGFloat(lanePositions[self.intel.player.currentLane] ?? 0), duration: 0.2))
            }
            
            MVAPopup.addAction(toPopup: &dialog, withTitle: "Swipe", type: .default) {
                continueWithSwipe()
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
                    if mManager.isDeviceMotionAvailable {
                        MVAPopup.addAction(toPopup: &dialog, withTitle: "Tilt", type: .default) {
                            continueWithControls(.precise)
                        }
                        self.cDelegate?.present(view: dialog, completion: {})
                    } else {
                        continueWithSwipe()
                    }
                    #elseif os(macOS)
                    self.cDelegate?.present(alert: dialog) { (resp: NSApplication.ModalResponse) in
                        switch resp {
                        case .alertFirstButtonReturn:
                            self.tutorialNode?.end(tutorialEnding)
                            self.cDelegate?.changeControls(to: .swipe)
                            self.physicsWorld.speed = 1.0
                            self.intel.stop = false
                            self.intel.player.run(SKAction.moveTo(x: CGFloat(lanePositions[self.intel.player.currentLane] ?? 0), duration: 0.8))
                        case .alertSecondButtonReturn:
                            self.tutorialNode?.end(tutorialEnding)
                            //self.cDelegate?.changeControls(to: .precise)
                            self.physicsWorld.speed = 1.0
                            self.intel.stop = false
                            NSCursor.hide()
                        default: break
                        }
                    }
                    #endif
                })]))
        } else {
            self.run(SKAction.sequence([
                SKAction.run({ self.tutorialNode?.prepareEnd() }),
                SKAction.wait(forDuration: 0.8),
                SKAction.run({
                    continueWithControls(.sphero)
                })]))
        }
    }
    
    // MARK: - Controls
    func handleSwipe(swipe: MVAPosition) {
        if gameStarted && physicsWorld.speed != 0.0 {
            if intel.player.changeLane(inDirection: swipe, pcsCalling: intel.playerLives > 0) == false {
                showPCSWarning()
                removeLife()
            } else {
                intel.sound.indicate(onNode: intel.player)
                
                if tutorialNode?.stage == 0 {
                    tutorialNode!.continueToTilting(playerCar: self.intel.player)
                }
            }
        }
    }
    
    func handleBrake(started: Bool) {
        if gameStarted {
            guard tutorialNode == nil || (tutorialNode?.stage ?? 0) >= 2 else { return }
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
    
    private lazy var carInset = intel.player.size.width/1.2
    private lazy var laneLeft = CGFloat(lanePositions[0]!)
    private lazy var laneRight = CGFloat(lanePositions[lanePositions.keys.max()!]!)
    private lazy var turnPCS = 0.0
    
    func handlePreciseMove(withDeltaX deltaX: CGFloat) {
        if gameStarted && physicsWorld.speed != 0.0 {//&& (tutorialNode == nil || tutorialNode?.stage != 0) {
            let newPlayerPos = self.intel.player.position.x + deltaX
            let carL = laneLeft-carInset
            let carR = laneRight+carInset
            let maxLeft = newPlayerPos <= carL
            let maxRight = newPlayerPos >= carR
            
            var carsBlockingDirection = Set<MVACar>()
            if intel.player.pcsActive && intel.playerLives > 0 {
                let closeDir = deltaX < 0 ? MVAPosition.closerLeft : MVAPosition.closerRight
                carsBlockingDirection = intel.player.responseFromSensors(inPositions: [closeDir])
            }
            
            if carsBlockingDirection.isEmpty && turnPCS <= 0 {
                switch (maxLeft, maxRight) {
                case (true, _): intel.player.run(SKAction.moveTo(x: carL, duration: 0.09))
                case (_, true): intel.player.run(SKAction.moveTo(x: carR, duration: 0.09))
                default: intel.player.run(SKAction.moveTo(x: newPlayerPos, duration: 0.09))
                }
                
                let closestLane = lanePositions.enumerated().min(by: { abs(CGFloat($0.element.value) - newPlayerPos) < abs(CGFloat($1.element.value) - newPlayerPos) })!
                intel.player.currentLane = closestLane.element.key
                
            } else {
                showPCSWarning()
                if turnPCS <= 0 {
                    removeLife()
                    turnPCS = 0.6
                }
            }
            
            if tutorialNode?.stage == 2 {
                tutorialNode?.continueToBraking()
            }
        }
    }
    
    func handlePreciseMove(toX newX: CGFloat) {
        if gameStarted && physicsWorld.speed != 0.0 {//&& (tutorialNode == nil || tutorialNode?.stage != -1) {
            let carL = laneLeft-carInset
            let carR = laneRight+carInset
            let maxLeft = newX <= carL
            let maxRight = newX >= carR
            
            var carsBlockingDirection = Set<MVACar>()
            if intel.player.pcsActive && intel.playerLives > 0 {
                let closeDir = (intel.player.position.x-newX) < 0 ? MVAPosition.closerLeft : MVAPosition.closerRight
                carsBlockingDirection = intel.player.responseFromSensors(inPositions: [closeDir])
            }
            
            if carsBlockingDirection.isEmpty && turnPCS <= 0 {
                switch (maxLeft, maxRight) {
                case (true, _):
                    intel.player.removeAllActions()
                    intel.player.run(SKAction.moveTo(x: carL, duration: 0.1))
                case (_, true):
                    intel.player.removeAllActions()
                    intel.player.run(SKAction.moveTo(x: carR, duration: 0.1))
                default: intel.player.run(SKAction.moveTo(x: newX, duration: 0.2))
                }
                
                let closestLane = lanePositions.enumerated().min(by: { abs(CGFloat($0.element.value) - newX) < abs(CGFloat($1.element.value) - newX) })!
                intel.player.currentLane = closestLane.element.key
                
            } else {
                showPCSWarning()
                if turnPCS <= 0 {
                    removeLife()
                    turnPCS = 0.6
                }
            }
            
            if tutorialNode?.stage == 0 {
                tutorialNode?.run(SKAction.sequence([SKAction.wait(forDuration: 2.0),
                                                     SKAction.run({ self.tutorialNode?.continueToBraking() })]))
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
            let begin = {
                self.isUserInteractionEnabled = false
                self.startGame()
            }
            #if os(iOS)
            if self.gameControls != .sphero {
                begin()
            } /*else if self.gameControls == .sphero && RKRobotDiscoveryAgent.shared().connectedRobots().count > 0 {
                begin()
            }*/
            #else
                begin()
            #endif
            
        } else if gameStarted && pauseBtt.contains(pos) {
            pauseGame(withAnimation: true)
        } else if gameStarted && playBtt.contains(pos) {
            resumeGame()
        }
    }
    
    // MARK: - SKPhysicsContactDelegate
    private var playerInCollision = false
    
    @objc func cancelPlayerCollision() { playerInCollision = false }
    
    #if os(iOS)
    //Sphero function
    func blinkSphero(withTime time: TimeInterval?, andColor color: (r: Float,g: Float,b: Float) = (1.0,0.0,0.0)) {
        /*self.sphero?.setLEDWithRed(color.r, green: color.g, blue: color.b)
        
        if time != nil {
            Timer.scheduledTimer(withTimeInterval: time!, repeats: false) { (tmr: Timer) in
                tmr.invalidate()
                self.sphero?.setLEDWithRed(0.0, green: 1.0, blue: 0.0)
            }
        }*/
    }
    #endif
    
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
                    generateSmoke(atPoint: contact.contactPoint, forTime: 15.0)
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
                    #if os(iOS)
                    if gameControls != .sphero {
                        let vibrator = UIImpactFeedbackGenerator(style: .medium)
                        vibrator.impactOccurred()
                    } else {
                        blinkSphero(withTime: 1.0)
                    }
                    #else
                    self.cDelegate?.showInInfoLabel("🚙💥🚗", forDuration: 1.0)
                    #endif
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
                    #if os(iOS)
                    if gameControls != .sphero {
                        let vibrator = UIImpactFeedbackGenerator(style: .heavy)
                        vibrator.impactOccurred()
                    } else {
                        blinkSphero(withTime: nil)
                    }
                    #else
                    self.cDelegate?.showInInfoLabel("🚙💥🚗", forDuration: 5.0)
                    #endif
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
        particles?.zPosition = 6.0
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

