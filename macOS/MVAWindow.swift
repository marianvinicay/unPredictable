//
//  MVAWindow.swift
//  unPredictable - macOS
//
//  Created by Majo on 07/10/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import Cocoa

class MVAWindow: NSWindow {
    override func awakeFromNib() {
        super.awakeFromNib()
        let screenSize = NSScreen.main!.visibleFrame
        let aspectRatio = CGFloat(0.75)
        
        let percent = CGFloat(0.80)
        let myHeight = screenSize.size.height * percent
        let myWidth = (myHeight/4)*3 // rest of 1.0 (1.0 - 0.75)

        setFrame(NSMakeRect(
            (screenSize.size.width/2)-(myWidth/2),
            (screenSize.size.height/2)-(myHeight/2),
            myWidth,
            myHeight),
                 display: true)
        
        let screenH = screenSize.height //??? other screens
        let minH = CGFloat(50*9)
        
        self.aspectRatio = NSSize(width: 3, height: 4)
        self.contentAspectRatio = NSSize(width: 3, height: 4)
        self.minSize = NSSize(width: minH*aspectRatio, height: minH)
        self.maxSize = NSSize(width: screenH*aspectRatio, height: screenH)
    }
}
