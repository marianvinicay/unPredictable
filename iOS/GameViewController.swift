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
    var scene: GameScene!

    override func viewDidLoad() {
        super.viewDidLoad()
        scene = GameScene.new(withSize: self.view.frame.size)

        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(scene)
        
        skView.ignoresSiblingOrder = true
        //skView.showsFPS = true
        //skView.showsNodeCount = true
        //skView.showsPhysics = true
        NotificationCenter.default.addObserver(self, selector: #selector(showAuthenticationViewController), name: MVAGameCenterHelper.authenticationCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toggleGCButton), name: MVAGameCenterHelper.toggleGCBtt, object: nil)
        
        if MVAMemory.enableGameCenter != false {
            scene.gameCHelper.authenticateLocalPlayer()
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    func toggleGCButton() {
        let animSpeed = 0.6
        if scene.physicsWorld.speed == 0.0 {
            self.gameCenterBtt.isHidden = false
            UIView.animate(withDuration: animSpeed, animations: {
                self.gameCenterBtt.alpha = 1.0
            })
        } else {
            UIView.animate(withDuration: animSpeed, animations: {
                self.gameCenterBtt.alpha = 0.0
            }, completion: { (_: Bool) in
                self.gameCenterBtt.isHidden = true
            })
        }
    }
    
    @IBAction func showGameCenter(_ sender: UIButton) {
        scene.gameCHelper.showGKGameCenterViewController(viewController: self)
    }
    
    func showAuthenticationViewController() {
        if let authenticationViewController =
            scene.gameCHelper.authenticationViewController {
            self.present(
                authenticationViewController,
                animated: true, completion: nil)
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
