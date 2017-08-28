//
//  ChangeCarScene_Keyboard.swift
//  unPredictable
//
//  Created by Majo on 26/08/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

extension ChangeCarScene {
    
    override func mouseUp(with event: NSEvent) {
        let point = self.convertPoint(fromView: event.locationInWindow)
        touchedPosition(point)
    }
    
    override func keyDown(with event: NSEvent) {
        interpretKeyEvents([event])
    }
    
    override func moveLeft(_ sender: Any?) {
        changeCar(-1)
    }
    
    override func moveRight(_ sender: Any?) {
        changeCar(1)
    }
}
