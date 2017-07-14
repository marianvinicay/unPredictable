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
    
    //@IBOutlet weak var distanceLbl: UILabel!
    
    @IBAction func playPauseGame(_ sender: UIButton) {
        if scene.isPaused {
            scene.isPaused = false
            UIView.animate(withDuration: 1.0, animations: {
                sender.setTitle("⏸", for: .normal)
                let side = self.view.frame.maxX - sender.frame.width
                let top = self.view.frame.minY  + sender.frame.height/2
                sender.center = CGPoint(x: side, y: top)
            })
        } else {
            scene.isPaused = true
            UIView.animate(withDuration: 1.0, animations: {
                sender.setTitle("▶️", for: .normal)
                sender.center = self.view.center
            })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        scene = GameScene.newGameScene(withSize: self.view.frame.size)
        //distanceLbl.superview?.layer.cornerRadius = 6.0
        //distanceLbl.superview?.clipsToBounds = true
        //distanceLbl.superview?.backgroundColor = .darkGray
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
