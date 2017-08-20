//
//  InterfaceController.swift
//  AWatch Extension
//
//  Created by Majo on 04/08/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import WatchKit
import SpriteKit

class GameController: WKInterfaceController {

    @IBOutlet var skInterface: WKInterfaceSKScene!
    private var scene: GameSceneWatch!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        scene = GameSceneWatch.newScene()
        // Present the scene
        self.skInterface.presentScene(scene)
        
        // Use a preferredFramesPerSecond that will maintain consistent frame rate
        self.skInterface.preferredFramesPerSecond = 30
        print("awake")
        //if MVAMemory.tutorialDisplayed && MVAMemory.enableGameCenter {
            //scene.intel.gameCHelper.authenticateLocalPlayer()
        //}
    }
    
    @IBAction func handleGesture(withGestureRecognizer gestureRecognizer: WKGestureRecognizer) {
        print("gest")
        /*if let swipe = gestureRecognizer as? WKSwipeGestureRecognizer {
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
        }*/
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
