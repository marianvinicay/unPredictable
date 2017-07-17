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
        let size = CGSize(width: self.view.bounds.width, height: self.view.bounds.height)
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
        if let oldOrigin = NSApp.mainWindow?.frame.origin {
            print("ha")
            NSApp.mainWindow?.setFrame(NSRect(origin: oldOrigin, size: gameScene.size), display: true)
        }
    }
    
}

