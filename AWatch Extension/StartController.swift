//
//  StartController.swift
//  unPredictable
//
//  Created by Majo on 05/08/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import WatchKit
import Foundation


class StartController: WKInterfaceController {

    @IBAction func startGame() {
        //let gameController = InterfaceController()
        //gameController.awake(withContext: nil)
        //self.presentController(withName: "game", context: nil)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
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
