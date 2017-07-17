//
//  InterfaceController.swift
//  watchOS Extension
//
//  Created by Majo on 25/08/16.
//  Copyright © 2016 MarVin. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    @IBOutlet var skInterface: WKInterfaceSKScene!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let scene = GameScene.new(withSize: self.contentFrame.size)
        
        // Present the scene
        self.skInterface.presentScene(scene)
        
        // Use a preferredFramesPerSecond that will maintain consistent frame rate
        self.skInterface.preferredFramesPerSecond = 30
    }
    
    @IBAction func handleGesture(gestureRecognizer : WKGestureRecognizer) {
        if let swipe = gestureRecognizer as? WKSwipeGestureRecognizer {
            if swipe.direction == .right {
                (skInterface.scene as? GameScene)?.handleSwipe(swipe: .right) //???gamescene as property?
            } else if swipe.direction == .left {
                (skInterface.scene as? GameScene)?.handleSwipe(swipe: .left)
            }
        } else if let press = gestureRecognizer as? WKLongPressGestureRecognizer {
            if press.state == .began {
                (skInterface.scene as? GameScene)?.handleBrake(started: true)
            } else if press.state == .ended {
                (skInterface.scene as? GameScene)?.handleBrake(started: false)
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
