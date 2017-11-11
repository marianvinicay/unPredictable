//
//  ChangeCarScene_Touch.swift
//  unPredictable
//
//  Created by Majo on 20/08/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import UIKit
import SpriteKit

extension ChangeCarScene: UIGestureRecognizerDelegate {
    override func didMove(to view: SKView) {
        setupSwipes()
    }
    
    func setupSwipes() {
        let right = UISwipeGestureRecognizer(target: self, action: #selector(swipeGesture(swipe:)))
        right.direction = .right
        
        let left = UISwipeGestureRecognizer(target: self, action: #selector(swipeGesture(swipe:)))
        left.direction = .left
        
        right.delegate = self
        left.delegate = self
        
        let back = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(goBack(eSwipe:)))
        back.edges = .left
        
        view?.addGestureRecognizer(right)
        view?.addGestureRecognizer(left)
        view?.addGestureRecognizer(back)
        
        myRecongizers = [right,left,back]
    }
    
    func removeSwipes() {
        myRecongizers.forEach({ view?.removeGestureRecognizer($0) })
    }
    
    @objc func swipeGesture(swipe: UIGestureRecognizer) {
        if (swipe as? UISwipeGestureRecognizer)?.direction == .left {
            changeCar(1)
        } else if (swipe as? UISwipeGestureRecognizer)?.direction == .right {
            changeCar(-1)
        }
    }
    
    @objc func goBack(eSwipe: UIGestureRecognizer) {
        if eSwipe is UIScreenEdgePanGestureRecognizer {
            if eSwipe.state == .began {
                backBttAction()
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!.location(in: self)
        touchedPosition(touch)
    }
}
