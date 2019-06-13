//
//  GameViewController.swift
//  unPredictable
//
//  Created by Marian Vinicay on 25/08/16.
//  Copyright © 2016 Marvin. All rights reserved.
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

    @IBOutlet weak var gameCenterBtt: UIButton!
    @IBOutlet weak var soundBtt: UIButton! {
        willSet {
            if MVAMemory.audioMuted {
                newValue.setImage(#imageLiteral(resourceName: "SoundOFF"), for: .normal)
            } else {
                newValue.setImage(#imageLiteral(resourceName: "SoundON"), for: .normal)
            }
        }
    }
    @IBOutlet weak var controlsBtt: UIButton! {
        willSet {
            switch MVAMemory.gameControls {
            case .swipe: newValue.setImage(#imageLiteral(resourceName: "phoneTouch"), for: .normal)
            case .precise: newValue.setImage(#imageLiteral(resourceName: "phoneTilt"), for: .normal)
            //case .sphero: newValue.setImage(#imageLiteral(resourceName: "sphero"), for: .normal)
            }
        }
    }
    @IBOutlet weak var changeCarBtt: UIButton! {
        willSet {
            newValue.layer.cornerRadius = 9
        }
    }
    @IBOutlet weak var spheroLabel: UILabel! {
        willSet {
            newValue.text = nil
        }
    }
    
    var scene: GameScene!

    override func viewDidLoad() {
        super.viewDidLoad()
        let sceneSize = self.view.frame.size
        scene = GameScene.new(withSize: sceneSize)
        scene.cDelegate = self
        
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
        NotificationCenter.default.addObserver(self, selector: #selector(changePlayerCar), name: ChangeCarViewController.changePCar, object: nil)
        
        // for Sphero
        //NotificationCenter.default.addObserver(self, selector: #selector(appBecomesActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(appResigns), name: UIApplication.willResignActiveNotification, object: nil)
        //RKRobotDiscoveryAgent.shared().addNotificationObserver(self, selector: #selector(handleRobotStateChangeNotification(notification:)))
        
        if MVAMemory.enableGameCenter {
            scene.intel.gameCHelper.authenticateLocalPlayer() { (granted: Bool) in
                if granted {
                    self.gameCenterBtt.isHidden = false
                } else {
                    self.gameCenterBtt.isHidden = true
                }
            }
        }
    }
    
    /*
    private func lookingForSphero() {
        spheroLabel.text = "Connecting to Sphero"
        scene.playBtt.alpha = 0.2
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { (tmr: Timer) in
            let connectedSphero = RKRobotDiscoveryAgent.shared().connectedRobots().count > 0
            if self.spheroLabel.text != nil && !connectedSphero {
                if self.spheroLabel.text!.hasSuffix("...") == true {
                    self.spheroLabel.text = "Connecting to Sphero"
                } else {
                    self.spheroLabel.text = self.spheroLabel.text!+"."
                }
            } else {
                tmr.invalidate()
                if connectedSphero {
                    self.scene.playBtt.alpha = 1.0
                    self.spheroLabel.text = "Sphero Online"
                }
            }
        }
    }
    
    @objc func handleRobotStateChangeNotification(notification: RKRobotChangedStateNotification) {
        switch (notification.type) {
        case .online:
            scene.sphero = RKConvenienceRobot(robot: notification.robot)
            scene.sphero!.enableLocator(false)
            scene.sphero!.enableCollisions(false)
            scene.sphero!.enableStabilization(false)
            scene.sphero!.add(scene)
            scene.sphero!.setLEDWithRed(0.0, green: 1.0, blue: 0.0)
            scene.sphero!.setBackLEDBrightness(0.3)
            scene.sphero!.setZeroHeading()
            RKRobotDiscoveryAgent.stopDiscovery()
            spheroLabel.text = "Sphero Online"
            scene.playBtt.alpha = 1.0
        case .failedConnect:
            RKRobotDiscoveryAgent.stopDiscovery()
            RKRobotDiscoveryAgent.startDiscovery()
            lookingForSphero()
        case .disconnected:
            scene.sphero = nil
        default: break
        }
    }
    
    @objc func appBecomesActive() {
        if MVAMemory.gameControls == .sphero {
            RKRobotDiscoveryAgent.startDiscovery()
            lookingForSphero()
        }
    }
    
    @objc func appResigns() {
        RKRobotDiscoveryAgent.shared().disconnectAll()
        scene.sphero = nil
        RKRobotDiscoveryAgent.stopDiscovery()
    }*/
    
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
            spheroLabel.isHidden = false
            if !scene.gameStarted {
                changeCarBtt.isHidden = false
            }
            UIView.animate(withDuration: animSpeed, animations: {
                self.controlsBtt.alpha = 1.0
                self.gameCenterBtt.alpha = 1.0
                self.soundBtt.alpha = 1.0
                self.spheroLabel.alpha = 1.0
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
                self.spheroLabel.alpha = 0.0
                if !self.scene.gameStarted {
                    self.changeCarBtt.alpha = 0.0
                }
            }, completion: { (_: Bool) in
                self.controlsBtt.isHidden = true
                self.gameCenterBtt.isHidden = true
                self.soundBtt.isHidden = true
                self.spheroLabel.isHidden = true
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
            spheroLabel.text = nil
            controlsBtt.setImage(#imageLiteral(resourceName: "phoneTouch"), for: .normal)
            scene.playBtt.alpha = 1.0
            scene.gameControls = .swipe
            scene.setupSwipes()
        case .precise:
            spheroLabel.text = nil
            controlsBtt.setImage(#imageLiteral(resourceName: "phoneTilt"), for: .normal)
            scene.playBtt.alpha = 1.0
            scene.gameControls = .precise
            scene.setupTilt()
            if scene.gameStarted {
                scene.startTilt()
            }
        /*case .sphero:
            controlsBtt.setImage(#imageLiteral(resourceName: "sphero"), for: .normal)
            //RKRobotDiscoveryAgent.startDiscovery()
            //lookingForSphero()
            
            scene.gameControls = .sphero
            scene.setupSphero()
            if scene.gameStarted {
                scene.startSphero()
            }*/
        }
    }
    
    @IBAction func toggleControls(_ sender: UIButton) {
        switch scene.gameControls {
        case .swipe where (UIApplication.shared.delegate as! AppDelegate).motionManager.isDeviceMotionAvailable: setControls(to: .precise)
        default: setControls(to: .swipe)
        }
        /*switch scene.gameControls {
        case .swipe:
            if (UIApplication.shared.delegate as! AppDelegate).motionManager.isDeviceMotionAvailable {
                setControls(to: .precise)
            } else {
                setControls(to: .sphero)
            }
        case .precise:
            setControls(to: .swipe)
        case .sphero:
            appResigns() //disconnect sphero
            setControls(to: .swipe)
        }*/
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
    
    @objc func changePlayerCar() {
        let pName = MVAMemory.playerCar
        if scene.intel.player.skin.name != pName {
            scene.intel.player.skin = MVASkin.createForCar(pName, withAtlas: scene.spawner.textures)
            scene.intel.player.texture = scene.intel.player.skin.normal
            scene.intel.player.resetPhysicsBody()
            scene.checkLives()
        }
    }
   
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func unwindToTMainMenu(segue: UIStoryboardSegue) {}
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destVC = (segue.destination as? UINavigationController)?.topViewController as? ChangeCarViewController {
            destVC.store = self.scene.intel.storeHelper
        }
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
