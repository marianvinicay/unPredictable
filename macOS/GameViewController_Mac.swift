//
//  GameViewController_Mac.swift
//  unPredictable
//
//  Created by Marian Vinicay on 25/08/16.
//  Copyright © 2016 Marvin. All rights reserved.
//

import Cocoa
import SpriteKit
import GameKit

class GameViewController_Mac: NSViewController, NSWindowDelegate, GameVCDelegate {
    
    func present(alert: NSAlert, completion: @escaping (NSApplication.ModalResponse) -> Void) {
        NSCursor.unhide()
        alert.beginSheetModal(for: NSApplication.shared.mainWindow!, completionHandler: completion)
    }
    
    func changeControls(to controls: MVAGameControls) {
        self.setControls(to: controls)
    }
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        changeCarVC?.view.window?.setContentSize(frameSize)
        return frameSize
    }
    
    @IBOutlet weak var gameCenterBtt: NSButton!
    @IBOutlet weak var changeCarBtt: NSButton!
    @IBOutlet weak var soundBtt: NSButton! {
        willSet {
            if MVAMemory.audioMuted {
                newValue.image = NSImage(named: "SoundOFF")
            } else {
                newValue.image = NSImage(named: "SoundON")
            }
        }
    }
    @IBOutlet weak var controlsLabel: NSTextField!
    @IBOutlet weak var controlsBtt: NSButton! {
        willSet {
            if MVAMemory.gameControls == .swipe {
                newValue.title = "Arrows"
            } else {
                newValue.title = "Mouse"
            }
        }
    }
        
    var gameScene: GameScene!
    private var changeCarVC: ChangeCarViewController_Mac?
    private var mouseMonitors = [Any?]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let size = self.view.frame.size
        gameScene = GameScene.new(withSize: size)
        gameScene.cDelegate = self
        
        let trackingArea = NSTrackingArea(rect: self.view.bounds, options: [.activeInKeyWindow,.mouseMoved], owner: self, userInfo: nil)
        self.view.addTrackingArea(trackingArea)
        
        if gameScene.gameControls == .precise {
            setUpMouseControls()
        }
        
        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(gameScene)
        skView.ignoresSiblingOrder = true
        
        //skView.showsFPS = true
        //skView.showsNodeCount = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(showAuthenticationViewController), name: MVAGameCenterHelper.authenticationCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toggleButtons), name: MVAGameCenterHelper.toggleBtts, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(backFromChangeCarScene), name: ChangeCarViewController_Mac.backFromScene, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changePlayerCar), name: ChangeCarViewController_Mac.changePCar, object: nil)
        
        if MVAMemory.tutorialDisplayed && MVAMemory.enableGameCenter {
            gameScene.intel.gameCHelper.authenticateLocalPlayer() { (granted: Bool) in
                if granted {
                    self.gameCenterBtt.isHidden = false
                } else {
                    self.gameCenterBtt.isHidden = true
                }
            }
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.delegate = self
    }
    
    @objc func toggleButtons(withAnimSpeed animSpeed: Double = 0.4) {
        if soundBtt.alphaValue < 1.0 {
            NSAnimationContext.runAnimationGroup({ (context: NSAnimationContext) in
                context.duration = animSpeed
                
                gameCenterBtt.animator().alphaValue = 1.0
                soundBtt.animator().alphaValue = 1.0
                controlsBtt.animator().alphaValue = 1.0
                controlsLabel.animator().alphaValue = 1.0
                
                gameCenterBtt.isEnabled = true
                soundBtt.isEnabled = true
                controlsBtt.isEnabled = true
                if !gameScene.gameStarted {
                    changeCarBtt.animator().alphaValue = 1.0
                    changeCarBtt.isEnabled = true
                }
            }, completionHandler: nil)
        } else {
            NSAnimationContext.runAnimationGroup({ (context: NSAnimationContext) in
                context.duration = animSpeed
                
                gameCenterBtt.animator().alphaValue = 0.0
                soundBtt.animator().alphaValue = 0.0
                controlsBtt.animator().alphaValue = 0.0
                controlsLabel.animator().alphaValue = 0.0
                
                gameCenterBtt.isEnabled = false
                soundBtt.isEnabled = false
                controlsBtt.isEnabled = false
                if !gameScene.gameStarted {
                    changeCarBtt.animator().alphaValue = 0.0
                    changeCarBtt.isEnabled = false
                }
            }, completionHandler: nil)
        }
    }
    
    @IBAction func toggleSound(_ sender: NSButton) {
        if gameScene.audioEngine.mainMixerNode.outputVolume > 0.0 {
            gameScene.audioEngine.mainMixerNode.outputVolume = 0.0
            MVAMemory.audioMuted = true
            soundBtt.image = NSImage(named: "SoundOFF")
        } else {
            gameScene.audioEngine.mainMixerNode.outputVolume = 1.0
            MVAMemory.audioMuted = false
            soundBtt.image = NSImage(named: "SoundON")
        }
    }
    
    private func setUpMouseControls() {
        mouseMonitors.append(NSEvent.addLocalMonitorForEvents(matching: .mouseMoved, handler: {
            if self.gameScene.gameStarted {
                self.gameScene.moveWithMouse(NSEvent.mouseLocation.x)
            }
            return $0
        }))
        
        mouseMonitors.append(NSEvent.addLocalMonitorForEvents(matching: .mouseEntered, handler: {
            if !self.gameScene.intel.stop && self.gameScene.gameStarted {
                NSCursor.hide()
            }
            return $0
        }))
        
        mouseMonitors.append(NSEvent.addLocalMonitorForEvents(matching: .mouseExited, handler: {
            NSCursor.unhide()
            return $0
        }))
    }
    
    private func setControls(to controls: MVAGameControls) {
        if controls == .swipe {
            controlsBtt.title = "Arrows"
            gameScene.gameControls = .swipe
            for monitor in mouseMonitors.filter({ $0 != nil }) {
                NSEvent.removeMonitor(monitor!)
            }
            mouseMonitors.removeAll()
        } else if controls == .precise {
            controlsBtt.title = "Mouse"
            gameScene.gameControls = .precise
            setUpMouseControls()
        }
    }
    
    @IBAction func toggleControls(_ sender: NSButton) {
        if gameScene.gameControls == .swipe {
            self.setControls(to: .precise)
        } else {
            self.setControls(to: .swipe)
        }
    }
    
    @IBAction func showGameCenter(_ sender: NSButton) {
        gameScene.intel.gameCHelper.showGKGameCenterViewController(viewController: self) { (granted: Bool) in
            if granted {
                self.gameCenterBtt.isHidden = false
            } else {
                self.gameCenterBtt.isHidden = true
            }
        }
    }
    
    @objc func showAuthenticationViewController() {
        if gameScene.gameStarted == false {
            if let authenticationViewController =
                gameScene.intel.gameCHelper.authenticationViewController {
                let sdc = GKDialogController.shared()
                sdc.parentWindow = NSApp.mainWindow
                sdc.present(authenticationViewController)
            }
        }
    }
    
    @objc func backFromChangeCarScene() {
        changeCarVC = nil
    }
    
    @objc func changePlayerCar() {
        let pName = MVAMemory.playerCar
        if gameScene.intel.player.skin.name != pName {
            gameScene.intel.player.skin = MVASkin.createForCar(pName, withAtlas: gameScene.spawner.textures)
            gameScene.intel.player.texture = gameScene.intel.player.skin.normal
            gameScene.intel.player.resetPhysicsBody()
            gameScene.checkLives()
        }
        backFromChangeCarScene()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let destVC = (segue.destinationController as? ChangeCarViewController_Mac) {
            changeCarVC = destVC
            destVC.store = self.gameScene.intel.storeHelper
            destVC.view.setFrameSize(self.view.frame.size)
        }
    }
}

