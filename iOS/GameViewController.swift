//
//  GameViewController.swift
//  (un)Predictable
//
//  Created by Majo on 25/08/16.
//  Copyright © 2016 MarVin. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

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
    var scene: GameScene!

    override func viewDidLoad() {
        super.viewDidLoad()
        scene = GameScene.new(withSize: self.view.frame.size)
        
        if MVAMemory.audioMuted {
            scene.audioEngine.mainMixerNode.outputVolume = 0.0
        }
        
        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(scene)
        
        skView.ignoresSiblingOrder = true
        //skView.showsFPS = true
        //skView.showsNodeCount = true
        //skView.showsPhysics = true
        NotificationCenter.default.addObserver(self, selector: #selector(showAuthenticationViewController), name: MVAGameCenterHelper.authenticationCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toggleButtons), name: MVAGameCenterHelper.toggleBtts, object: nil)
        
        if MVAMemory.tutorialDisplayed && MVAMemory.enableGameCenter {
            scene.intel.gameCHelper.authenticateLocalPlayer()
        }
        scene.intel.healthKHelper.initiateKit()
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    func toggleButtons() {
        let animSpeed = 0.6
        if gameCenterBtt.isHidden {
            gameCenterBtt.isHidden = false
            soundBtt.isHidden = false
            UIView.animate(withDuration: animSpeed, animations: {
                self.gameCenterBtt.alpha = 1.0
                self.soundBtt.alpha = 1.0
            })
        } else {
            UIView.animate(withDuration: animSpeed, animations: {
                self.gameCenterBtt.alpha = 0.0
                self.soundBtt.alpha = 0.0
            }, completion: { (_: Bool) in
                self.gameCenterBtt.isHidden = true
                self.soundBtt.isHidden = true
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
    
    @IBAction func showGameCenter(_ sender: UIButton) {
        scene.intel.gameCHelper.showGKGameCenterViewController(viewController: self)
    }
    
    func showAuthenticationViewController() {
        if scene.gameStarted == false {
            if let authenticationViewController =
                scene.intel.gameCHelper.authenticationViewController {
                self.present(
                    authenticationViewController,
                    animated: true, completion: nil)
            }
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
