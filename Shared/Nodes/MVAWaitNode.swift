//
//  MVAWaitNode.swift
//  unPredictable
//
//  Created by Majo on 14/08/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import UIKit

class MVAWaitView: UIView {
    #if os(iOS) || os(tvOS)
        private var activityInd: UIActivityIndicatorView?
    #elseif os(macOS)
        private var activityInd: NSProgressIndicator?
    #endif
    
    class func new(withSize size: CGSize) -> MVAWaitView {
        let newView = MVAWaitView(frame: CGRect(origin: .zero, size: size))
        newView.backgroundColor = UIColor(white: 0.0, alpha: 0.6)
        
        #if os(iOS) || os(tvOS)
            newView.activityInd = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            newView.activityInd!.center = CGPoint(x: newView.frame.midX, y: newView.frame.midY)
            newView.activityInd!.startAnimating()
        #elseif os(macOS)
            newNode.activityInd = NSProgressIndicator()
            newNode.activityInd!.style = .spinning
            newNode.activityInd!.frame = NSRect(x: (scene.size.width/2)-(150/2), y: (scene.size.height/2)-(150/2), width: 150, height: 150)
            let lighten = CIFilter(name: "CIColorControls")!
            lighten.setDefaults()
            lighten.setValue(1, forKey: "inputBrightness")
            newNode.activityInd!.contentFilters = [lighten]
            newNode.activityInd!.display()
            newNode.activityInd!.startAnimation(nil)
        #endif
        newView.addSubview(newView.activityInd!)
        
        return newView
    }
    
    func remove() {
        #if os(iOS) || os(tvOS)
            self.activityInd?.stopAnimating()
        #elseif os(macOS)
            self.activityInd?.stopAnimation(nil)
        #endif
        self.activityInd?.removeFromSuperview()
        self.removeFromSuperview()
    }
}
