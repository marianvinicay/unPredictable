//
//  MVAWaitNode.swift
//  unPredictable
//
//  Created by Majo on 14/08/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

class MVAWaitNode: SKNode {
    #if os(iOS) || os(tvOS)
        private var activityInd: UIActivityIndicatorView?
    #elseif os(macOS)
        private var activityInd: NSProgressIndicator?
    #endif
    
    class func new(withSize size: CGSize, inScene scene: SKScene) -> MVAWaitNode {
        let newNode = MVAWaitNode()
        
        let backG = SKSpriteNode(color: .black, size: size)
        backG.alpha = 0.6
        newNode.addChild(backG)
        backG.position = .zero
        
        #if os(iOS) || os(tvOS)
            newNode.activityInd = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            newNode.activityInd!.center = CGPoint(x: scene.view!.frame.midX, y: scene.view!.frame.midY)
            newNode.activityInd!.startAnimating()
        #elseif os(macOS)
            newNode.activityInd = NSProgressIndicator()
            newNode.activityInd!.style = .spinningStyle
            newNode.activityInd!.setFrameOrigin(NSPoint(x: scene.view!.frame.midX, y: scene.view!.frame.midY))
            newNode.activityInd!.startAnimation(nil)
        #endif
        scene.view!.addSubview(newNode.activityInd!)
        
        return newNode
    }
    
    func remove() {
        #if os(iOS) || os(tvOS)
            self.activityInd?.stopAnimating()
        #elseif os(macOS)
            self.activityInd?.stopAnimation(nil)
        #endif
        self.activityInd?.removeFromSuperview()
        self.removeFromParent()
    }
}
