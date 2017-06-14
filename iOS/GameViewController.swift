//
//  GameViewController.swift
//  (un)Predictable
//
//  Created by Majo on 25/08/16.
//  Copyright © 2016 MarVin. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    private var scene: GameScene?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scene = GameScene.newGameScene(withSize: self.view.frame.size)

        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(scene)
        
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
    }

    override var shouldAutorotate: Bool {
        return true
    }

    @IBAction func newSpawnSpeed(_ sender: UISegmentedControl) {
        var time = 2.0
        switch sender.selectedSegmentIndex {
        case 0: time = 1.0
        case 1: time = 2.0
        case 2: time = 5.0
        default: break
        }
        scene?.removeAction(forKey: "spawn")
        let spawn = SKAction.run {
            self.scene?.spawner.spawn(withExistingCars: self.scene!.bots, roadLanes: self.scene!.lanePositions)
        }
        let wait = SKAction.wait(forDuration: time)
        scene?.run(SKAction.repeatForever(SKAction.sequence([spawn,wait])), withKey: "spawn")
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
