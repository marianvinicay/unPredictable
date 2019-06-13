//
//  AppDelegate.swift
//  unPredictable
//
//  Created by Marian Vinicay on 25/08/16.
//  Copyright © 2016 Marvin. All rights reserved.
//

import Cocoa
import StoreKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, SKPaymentTransactionObserver {

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        inStore.paymentQueue(queue, updatedTransactions: transactions)
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        inStore.paymentQueueRestoreCompletedTransactionsFinished(queue)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        inStore.paymentQueue(queue, restoreCompletedTransactionsFailedWithError: error)
    }
    
    let inStore = MVAStore()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        SKPaymentQueue.default().add(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        SKPaymentQueue.default().remove(self)
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        if let scene = (NSApp.mainWindow?.contentViewController as? GameViewController_Mac)?.gameScene {
            if scene.gameStarted && scene.intel.stop == false {
                scene.pauseGame(withAnimation: true)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

}
