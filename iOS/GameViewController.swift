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

    private var scene: GameScene!

    override func viewDidLoad() {
        super.viewDidLoad()
        scene = GameScene.new(withSize: self.view.frame.size)
        MVAMemory.maxPlayerDistance = 0.3
        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(scene)
        
        skView.ignoresSiblingOrder = true
        //skView.showsFPS = true
        //skView.showsNodeCount = true
    }

    override var shouldAutorotate: Bool {
        return true
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
}
