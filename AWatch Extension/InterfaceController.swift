//
//  InterfaceController.swift
//  AWatch Extension
//
//  Created by Majo on 04/08/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import WatchKit
import SpriteKit

class InterfaceController: WKInterfaceController {

    @IBOutlet var skInterface: WKInterfaceSKScene!
    private var scene: GameScene!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        scene = GameScene.new(withSize: self.contentFrame.size)
        // Present the scene
        self.skInterface.presentScene(scene)
        
        // Use a preferredFramesPerSecond that will maintain consistent frame rate
        self.skInterface.preferredFramesPerSecond = 30
        
        scene.intel.healthKHelper.initiateKit()
        //if MVAMemory.tutorialDisplayed && MVAMemory.enableGameCenter {
            scene.intel.gameCHelper.authenticateLocalPlayer()
        //}
    }
    
    @IBAction func handleGesture(gestureRecognizer : WKGestureRecognizer) {
        if let swipe = gestureRecognizer as? WKSwipeGestureRecognizer {
            if swipe.direction == .right {
                scene.handleSwipe(swipe: .right)
            } else if swipe.direction == .left {
                scene.handleSwipe(swipe: .left)
            }
        } else if let press = gestureRecognizer as? WKLongPressGestureRecognizer {
            if press.state == .began {
                scene.handleBrake(started: true)
            } else if press.state == .ended {
                scene.handleBrake(started: false)
            }
        } else if let tap = gestureRecognizer as? WKTapGestureRecognizer {
            if scene.playBtt.contains(tap.locationInObject())  {
                scene.startGame()
            }
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
