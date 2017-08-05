//
//  GameViewController.swift
//  macOS
//
//  Created by Majo on 25/08/16.
//  Copyright © 2016 MarVin. All rights reserved.
//

import Cocoa
import SpriteKit

class GameViewController: NSViewController {

    private var gameScene: GameScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let size = CGSize(width: 1024, height: 1366)
        NSApp.mainWindow?.minSize = NSSize(width: 1024, height: 1366)
        gameScene = GameScene.new(withSize: size)
        
        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(gameScene)
        
        skView.ignoresSiblingOrder = true
        
        skView.showsFPS = true
        skView.showsNodeCount = true
    }

    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
}

