//
//  GameViewController.swift
//  (un)Predictable
//
//  Created by Majo on 25/08/16.
//  Copyright © 2016 MarVin. All rights reserved.
//

import UIKit
import StoreKit
import SpriteKit

class GameViewController: UIViewController, GameVCDelegate {
    
    func present(view: UIViewController, completion: @escaping ()->Void) {
        self.present(view, animated: true, completion: completion)
    }
    
    func changeControls(to controls: MVAGameControls) {
        setControls(to: controls)
    }

    @IBOutlet weak var controlsBtt: UIButton! {
        willSet {
            if MVAMemory.gameControls == .swipe {
                newValue.setImage(#imageLiteral(resourceName: "phoneTouch"), for: .normal)
            } else {
                newValue.setImage(#imageLiteral(resourceName: "phoneTilt"), for: .normal)
            }
        }
    }
    @IBOutlet weak var gameCenterBtt: UIButton!
    @IBOutlet weak var changeCarBtt: UIButton! {
        willSet {
            newValue.layer.cornerRadius = 9
        }
    }
    @IBOutlet weak var soundBtt: UIButton! {
        willSet {
            if MVAMemory.audioMuted {
                newValue.setImage(#imageLiteral(resourceName: "SoundOFF"), for: .normal)
            } else {
                newValue.setImage(#imageLiteral(resourceName: "SoundON"), for: .normal)
            }
        }
    }
    var scene: GameScene!
    var changeCarScene: ChangeCarScene!

    override func viewDidLoad() {
        super.viewDidLoad()
        let sceneSize = self.view.frame.size
        scene = GameScene.new(withSize: sceneSize)
        scene.cDelegate = self
        changeCarScene = ChangeCarScene.new(withSize: sceneSize, andStore: scene.intel.storeHelper)
        
        if MVAMemory.audioMuted {
            scene.audioEngine.mainMixerNode.outputVolume = 0.0
        }
        
        let skView = self.view as! SKView
        skView.presentScene(scene)
        
        skView.ignoresSiblingOrder = true
        //skView.showsFPS = true
        //skView.showsNodeCount = true
        //skView.showsPhysics = true
        NotificationCenter.default.addObserver(self, selector: #selector(showAuthenticationViewController), name: MVAGameCenterHelper.authenticationCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toggleButtonsSEL), name: MVAGameCenterHelper.toggleBtts, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(backFromChangeCarScene), name: ChangeCarScene.backFromScene, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changePlayerCar), name: ChangeCarScene.changePCar, object: nil)
        
        if MVAMemory.tutorialDisplayed && MVAMemory.enableGameCenter {
            scene.intel.gameCHelper.authenticateLocalPlayer() { (granted: Bool) in
                if granted {
                    self.gameCenterBtt.isHidden = false
                } else {
                    self.gameCenterBtt.isHidden = true
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        }
    }
    
    @objc func toggleButtonsSEL() {
        toggleButtons()
    }
    
    private var bttnsHidden = false
    func toggleButtons(withAnimSpeed animSpeed: Double = 0.4) {
        if bttnsHidden {
            bttnsHidden = false
            controlsBtt.isHidden = false
            gameCenterBtt.isHidden = false
            soundBtt.isHidden = false
            if !scene.gameStarted {
                changeCarBtt.isHidden = false
            }
            UIView.animate(withDuration: animSpeed, animations: {
                self.controlsBtt.alpha = 1.0
                self.gameCenterBtt.alpha = 1.0
                self.soundBtt.alpha = 1.0
                if !self.scene.gameStarted {
                    self.changeCarBtt.alpha = 1.0
                }
            }, completion: { (_: Bool) in
                if !self.scene.gameStarted {
                    self.changeCarBtt.isEnabled = true
                }
            })
        } else {
            bttnsHidden = true
            UIView.animate(withDuration: animSpeed, animations: {
                self.controlsBtt.alpha = 0.0
                self.gameCenterBtt.alpha = 0.0
                self.soundBtt.alpha = 0.0
                if !self.scene.gameStarted {
                    self.changeCarBtt.alpha = 0.0
                }
            }, completion: { (_: Bool) in
                self.controlsBtt.isHidden = true
                self.gameCenterBtt.isHidden = true
                self.soundBtt.isHidden = true
                if !self.scene.gameStarted {
                    self.changeCarBtt.isHidden = true
                    self.changeCarBtt.isEnabled = false
                }
            })
        }
    }
    
    @IBAction func toggleSound(_ sender: UIButton) {
        if scene.audioEngine.mainMixerNode.outputVolume > 0.0 {
            scene.audioEngine.mainMixerNode.outputVolume = 0.0
            MVAMemory.audioMuted = true
            soundBtt.setImage(#imageLiteral(resourceName: "SoundOFF"), for: .normal)
        } else {
            scene.fadeInVolume()
            MVAMemory.audioMuted = false
            soundBtt.setImage(#imageLiteral(resourceName: "SoundON"), for: .normal)
        }
    }
    
    private func setControls(to controls: MVAGameControls) {
        switch controls {
        case .swipe:
            controlsBtt.setImage(#imageLiteral(resourceName: "phoneTouch"), for: .normal)
            scene.gameControls = .swipe
            scene.setupSwipes()
        case .precise:
            controlsBtt.setImage(#imageLiteral(resourceName: "phoneTilt"), for: .normal)
            scene.gameControls = .precise
            scene.setupTilt()
        }
    }
    
    @IBAction func toggleControls(_ sender: UIButton) {
        if scene.gameControls == .swipe && (UIApplication.shared.delegate as! AppDelegate).motionManager.isDeviceMotionAvailable {
            setControls(to: .precise)
        } else {
            setControls(to: .swipe)
        }
    }
    
    @IBAction func showGameCenter(_ sender: UIButton) {
        scene.intel.gameCHelper.showGKGameCenterViewController(viewController: self) { (granted: Bool) in
            if granted {
                self.gameCenterBtt.isHidden = false
            } else {
                self.gameCenterBtt.isHidden = true
            }
        }
    }
    
    @objc func showAuthenticationViewController() {
        if scene.gameStarted == false {
            if let authenticationViewController =
                scene.intel.gameCHelper.authenticationViewController {
                self.present(
                    authenticationViewController,
                    animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func showChangeCar(_ sender: UIButton) {
        toggleButtons()
        changeCarScene.refresh()
        let transition = SKTransition.reveal(with: .left, duration: 0.8)
        (self.view as! SKView).presentScene(changeCarScene, transition: transition)
    }
    
    
    
    @objc func backFromChangeCarScene() {
        toggleButtons(withAnimSpeed: 1.0)
        let transition = SKTransition.moveIn(with: .left, duration: 0.8)
        (self.view as! SKView).presentScene(scene, transition: transition)
    }
    
    @objc func changePlayerCar() {
        let pName = MVAMemory.playerCar
        if scene.intel.player.skin.name != pName {
            scene.intel.player.skin = MVASkin.createForCar(pName, withAtlas: scene.spawner.textures)
            scene.intel.player.texture = scene.intel.player.skin.normal
            scene.intel.player.resetPhysicsBody()
            scene.checkLives()
        }
        backFromChangeCarScene()
    }
   
    override var shouldAutorotate: Bool {
        return false
    }
    
    /*override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .all
        }
    }*/
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
