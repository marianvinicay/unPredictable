//
//  AppDelegate.swift
//  (un)Predictable
//
//  Created by Majo on 25/08/16.
//  Copyright © 2016 MarVin. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSApp.mainWindow?.aspectRatio = NSSize(width: 512, height: 683)
        NSApp.mainWindow?.contentAspectRatio = NSSize(width: 512, height: 683)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        if let scene = (NSApp.mainWindow?.contentViewController as? GameViewControllerMAC)?.gameScene {
            if scene.gameStarted && scene.intel.stop == false {
                scene.pauseGame(withAnimation: true)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

}

