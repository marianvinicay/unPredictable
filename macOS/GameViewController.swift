//
//  GameViewController.swift
//  macOS
//
//  Created by Majo on 25/08/16.
//  Copyright © 2016 MarVin. All rights reserved.
//

import Cocoa
import SpriteKit
import GameplayKit

class GameViewController: NSViewController {

    override func viewDidLoad() {
        @IBOutlet weak var strt: UIButton!
        super.viewDidLoad()
        let size = CGSize(width: self.view.bounds.width, height: self.view.bounds.height)
        let scene = GameScene.newGameScene(withSize: size)
        
        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(scene)
        
        skView.ignoresSiblingOrder = true
        
        skView.showsFPS = true
        skView.showsNodeCount = true
    }

}

