//
//  GameTouchbar.swift
//  unPredictable - macOS
//
//  Created by Majo on 17/12/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import Cocoa

@available(OSX 10.12.2, *)
extension NSTouchBarItem.Identifier {
    static let distanceLabel = NSTouchBarItem.Identifier("com.mva.un.dist")
    static let infoLabel = NSTouchBarItem.Identifier("com.mva.un.info")
}

@available(OSX 10.12.2, *)
extension GameViewControllerMAC: NSTouchBarDelegate {
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        
        touchBar.customizationIdentifier = NSTouchBar.CustomizationIdentifier(rawValue: "gameBar")
        touchBar.defaultItemIdentifiers = [.distanceLabel, .flexibleSpace, .infoLabel, .flexibleSpace]
        touchBar.customizationAllowedItemIdentifiers = [.distanceLabel, .infoLabel]
        return touchBar
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case .distanceLabel:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            customViewItem.view = NSTextField(labelWithString: "")
            return customViewItem
        case .infoLabel:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            customViewItem.view = NSTextField(labelWithString: "")
            return customViewItem
        default: return nil
        }
    }
}
