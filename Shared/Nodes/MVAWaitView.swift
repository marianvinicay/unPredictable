//
//  MVAWaitNode.swift
//  unPredictable
//
//  Created by Marian Vinicay on 14/08/2017.
//  Copyright © 2017 Marvin. All rights reserved.
//

#if os(iOS)
import UIKit

class MVAWaitView: UIView {
    private var activityInd: UIActivityIndicatorView?
    
    class func new(withSize size: CGSize) -> MVAWaitView {
        let newView = MVAWaitView(frame: CGRect(origin: .zero, size: size))
        newView.backgroundColor = UIColor(white: 0.0, alpha: 0.8)
        
        newView.activityInd = UIActivityIndicatorView(style: .whiteLarge)
        newView.activityInd!.center = CGPoint(x: newView.frame.midX, y: newView.frame.midY)
        newView.activityInd!.startAnimating()
        
        newView.addSubview(newView.activityInd!)
        
        return newView
    }
    
    func remove() {
        self.activityInd?.stopAnimating()
        self.activityInd?.removeFromSuperview()
        self.removeFromSuperview()
    }
}

#elseif os(macOS)
import AppKit

class MVAWaitView: NSView {
    private var activityInd: NSProgressIndicator?
    
    class func new(withSize size: CGSize) -> MVAWaitView {
        let newView = MVAWaitView(frame: CGRect(origin: .zero, size: size))
        newView.wantsLayer = true
        newView.layer?.backgroundColor = CGColor(gray: 0.0, alpha: 0.8)
        
        newView.activityInd = NSProgressIndicator()
        newView.activityInd!.style = .spinning
        newView.activityInd!.frame = NSRect(x: (size.width/2)-(150/2), y: (size.height/2)-(150/2), width: 150, height: 150)
        let lighten = CIFilter(name: "CIColorControls")!
        lighten.setDefaults()
        lighten.setValue(1, forKey: "inputBrightness")
        newView.activityInd!.contentFilters = [lighten]
        newView.activityInd!.display()
        newView.activityInd!.startAnimation(nil)
        newView.addSubview(newView.activityInd!)
        
        return newView
    }
    
    func remove() {
        self.activityInd?.stopAnimation(nil)
        self.activityInd?.removeFromSuperview()
        self.removeFromSuperview()
    }
}
#endif
