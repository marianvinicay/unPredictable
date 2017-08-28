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

class GameViewControllerMAC: NSViewController {
    
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
    
    var gameScene: GameScene!
    var changeCarScene: ChangeCarScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let size = NSSize(width: 512, height: 683)
        gameScene = GameScene.new(withSize: size)
        changeCarScene = ChangeCarScene.new(withSize: size, andStore: gameScene.intel.storeHelper)
        
        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(gameScene)
        
        skView.ignoresSiblingOrder = true
        
        skView.showsFPS = true
        skView.showsNodeCount = true
        
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
    
    func toggleButtons(withAnimSpeed animSpeed: Double = 0.4) {
        if soundBtt.alphaValue < 1.0 {
            gameCenterBtt.isHidden = false
            soundBtt.isHidden = false
            if !gameScene.gameStarted {
                changeCarBtt.isHidden = false
            }
            gameCenterBtt.animator().alphaValue = 1.0
            soundBtt.animator().alphaValue = 1.0
            if !gameScene.gameStarted {
                changeCarBtt.animator().alphaValue = 1.0
                changeCarBtt.isEnabled = true
            }
        } else {
            gameCenterBtt.animator().alphaValue = 0.0
            soundBtt.animator().alphaValue = 0.0
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
            soundBtt.image = NSImage(named: "SoundOFF")
        } else {
            gameScene.fadeInVolume()
            MVAMemory.audioMuted = false
            soundBtt.image = NSImage(named: "SoundON")
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
    
    func showAuthenticationViewController() {
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
    
    
    
    func backFromChangeCarScene() {
        toggleButtons(withAnimSpeed: 1.0)
        let transition = SKTransition.moveIn(with: .up, duration: 0.8)
        (self.view as! SKView).presentScene(gameScene, transition: transition)
    }
    
    func changePlayerCar() {
        let pName = MVAMemory.playerCar
        if gameScene.intel.player.skin.name != pName {
            gameScene.intel.player.skin = MVASkin.createForCar(pName, withAtlas: gameScene.spawner.textures)
            gameScene.intel.player.texture = gameScene.intel.player.skin.normal
            gameScene.intel.player.resetPhysicsBody()
            gameScene.checkLives()
        }
        backFromChangeCarScene()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
}

