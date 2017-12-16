//
//  GameViewController.swift
//  macOS
//
//  Created by Majo on 25/08/16.
//  Copyright © 2016 MarVin. All rights reserved.
//

import Cocoa
import SpriteKit
import GameKit

class GameViewControllerMAC: NSViewController, NSTouchBarDelegate, GameVCDelegate {
    
    func present(alert: NSAlert, completion: @escaping (NSApplication.ModalResponse) -> Void) {
        alert.beginSheetModal(for: NSApplication.shared.mainWindow!, completionHandler: completion)
    }
    
    func changeControls(to controls: MVAGameControls) {
        self.setControls(to: controls)
    }
    
    @available(OSX 10.12.2, *)
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        // 2
        touchBar.customizationIdentifier = NSTouchBar.CustomizationIdentifier("idk")
        // 3
        touchBar.defaultItemIdentifiers = [NSTouchBarItem.Identifier("idk")]
        // 4
        touchBar.customizationAllowedItemIdentifiers = [NSTouchBarItem.Identifier("idk")]
        return touchBar
    }
    
    @available(OSX 10.12.2, *)
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        let customViewItem = NSCustomTouchBarItem(identifier: identifier)
        customViewItem.view = NSTextField(labelWithString: "\u{1F30E} TEST")
        return customViewItem
    }
    
    @IBOutlet weak var gameCenterBtt: NSButton!
    @IBOutlet weak var changeCarBtt: NSButton!
    @IBOutlet weak var soundBtt: NSButton! {
        willSet {
            if MVAMemory.audioMuted {
                newValue.image = NSImage(named: NSImage.Name(rawValue: "SoundOFF"))
            } else {
                newValue.image = NSImage(named: NSImage.Name(rawValue: "SoundON"))
            }
        }
    }
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
    var changeCarScene: ChangeCarScene!
    private var mouseMonitors = [Any?]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let size = self.view.frame.size
        gameScene = GameScene.new(withSize: size)
        gameScene.cDelegate = self
        
        changeCarScene = ChangeCarScene.new(withSize: size, andStore: gameScene.intel.storeHelper)
        
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
        NotificationCenter.default.addObserver(self, selector: #selector(backFromChangeCarScene), name: ChangeCarScene.backFromScene, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changePlayerCar), name: ChangeCarScene.changePCar, object: nil)
        
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
    
    @objc func toggleButtons(withAnimSpeed animSpeed: Double = 0.4) {
        if soundBtt.alphaValue < 1.0 {
            gameCenterBtt.animator().alphaValue = 1.0
            soundBtt.animator().alphaValue = 1.0
            controlsBtt.animator().alphaValue = 1.0
            
            gameCenterBtt.isEnabled = true
            soundBtt.isEnabled = true
            controlsBtt.isEnabled = true
            if !gameScene.gameStarted {
                changeCarBtt.animator().alphaValue = 1.0
                changeCarBtt.isEnabled = true
            }
        } else {
            gameCenterBtt.animator().alphaValue = 0.0
            soundBtt.animator().alphaValue = 0.0
            controlsBtt.animator().alphaValue = 0.0
            
            gameCenterBtt.isEnabled = false
            soundBtt.isEnabled = false
            controlsBtt.isEnabled = false
            if !gameScene.gameStarted {
                changeCarBtt.animator().alphaValue = 0.0
                changeCarBtt.isEnabled = false
            }
        }
    }
    
    @IBAction func toggleSound(_ sender: NSButton) {
        if gameScene.audioEngine.mainMixerNode.outputVolume > 0.0 {
            gameScene.audioEngine.mainMixerNode.outputVolume = 0.0
            MVAMemory.audioMuted = true
            soundBtt.image = NSImage(named: NSImage.Name(rawValue: "SoundOFF"))
        } else {
            gameScene.audioEngine.mainMixerNode.outputVolume = 1.0
            MVAMemory.audioMuted = false
            soundBtt.image = NSImage(named: NSImage.Name(rawValue: "SoundON"))
        }
    }
    
    private func setUpMouseControls() {
        mouseMonitors.append(NSEvent.addLocalMonitorForEvents(matching: .mouseMoved, handler: {
            if self.gameScene.gameStarted {
                self.gameScene.moveWithMouse(NSEvent.mouseLocation.x)
            }
            return $0
        }))
       /* mouseMonitors.append(NSEvent.addLocalMonitorForEvents(matching: .mouseEntered, handler: {
            if !self.gameScene.intel.stop {
                NSCursor.hide()
            }
            return $0
        }))
        mouseMonitors.append(NSEvent.addLocalMonitorForEvents(matching: .mouseExited, handler: {
            NSCursor.unhide()
            return $0
        }))
        */
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
    
    @IBAction func showChangeCar(_ sender: NSButton) {
        toggleButtons()
        changeCarScene.refresh()
        let transition = SKTransition.reveal(with: .up, duration: 0.8)
        (self.view as! SKView).presentScene(changeCarScene, transition: transition)
    }
    
    @objc func backFromChangeCarScene() {
        toggleButtons(withAnimSpeed: 1.0)
        let transition = SKTransition.moveIn(with: .up, duration: 0.8)
        (self.view as! SKView).presentScene(gameScene, transition: transition)
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
}

