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
            newNode.activityInd!.style = .spinning
            let winSize = NSApp.mainWindow!.minSize
            newNode.activityInd!.frame = NSRect(x: (winSize.width/2)-31.5, y: (winSize.height/2)-31.5, width: 150, height: 150)
            let lighten = CIFilter(name: "CIColorControls")!
            lighten.setDefaults()
            lighten.setValue(1, forKey: "inputBrightness")
            newNode.activityInd!.contentFilters = [lighten]
            newNode.activityInd!.display()
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
