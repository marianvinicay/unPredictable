//
//  GameViewController.swift
//  tvOS
//
//  Created by Majo on 25/08/16.
//  Copyright © 2016 MarVin. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    
    
    private var gameScene: GameScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameScene = GameScene.newGameScene(withSize: CGSize())
        
        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(gameScene)
        
        skView.ignoresSiblingOrder = true
        
        skView.showsFPS = true
        skView.showsNodeCount = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
