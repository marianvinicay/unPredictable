//
//  MVAWaitNode.swift
//  unPredictable
//
//  Created by Majo on 14/08/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

#if os(iOS) || os(tvOS)
class MVAWaitNode: SKNode {
    private var activityInd: UIActivityIndicatorView?
    
    class func new(withSize size: CGSize, inScene scene: SKScene) -> MVAWaitNode {
        let newNode = MVAWaitNode()
        
        let backG = SKSpriteNode(color: .black, size: size)
        backG.alpha = 0.6
        newNode.addChild(backG)
        backG.position = .zero
        
        newNode.activityInd = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        newNode.activityInd!.center = CGPoint(x: scene.view!.frame.midX, y: scene.view!.frame.midY)
        newNode.activityInd!.startAnimating()
        scene.view!.addSubview(newNode.activityInd!)
        
        return newNode
    }
    
    func remove() {
        self.activityInd?.stopAnimating()
        self.activityInd?.removeFromSuperview()
        self.removeFromParent()
    }
}
#endif
