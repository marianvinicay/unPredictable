//
//  MVAWindow.swift
//  unPredictable
//
//  Created by Marian Vinicay on 07/10/2017.
//  Copyright © 2017 Marvin. All rights reserved.
//

import Cocoa

class MVAWindow: NSWindow {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let screenSize = NSScreen.main!.visibleFrame
        let aspectRatio = CGFloat(0.75)
        
        let percent = CGFloat(0.80)
        let myHeight = screenSize.size.height * percent
        let myWidth = (myHeight/4)*3
        setFrame(NSMakeRect(
            (screenSize.size.width/2)-(myWidth/2),
            (screenSize.size.height/2)-(myHeight/2),
            myWidth,
            myHeight),
                 display: true)
        setContentSize(NSSize(width: myWidth, height: myHeight))
        
        let screenH = screenSize.height
        let minH = CGFloat(50*9)
        
        self.aspectRatio = NSSize(width: 3, height: 4)
        self.contentAspectRatio = NSSize(width: 3, height: 4)
        self.minSize = NSSize(width: minH*aspectRatio, height: minH)
        self.maxSize = NSSize(width: screenH*aspectRatio, height: screenH)
    }
    
}
