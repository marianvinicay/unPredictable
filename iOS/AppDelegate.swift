//
//  AppDelegate.swift
//  unPredictable
//
//  Created by Marian Vinicay on 25/08/16.
//  Copyright © 2016 Marvin. All rights reserved.
//

import UIKit
import AVFoundation
import StoreKit
import CoreMotion

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SKPaymentTransactionObserver {
    
    var window: UIWindow?
    
    let inStore = MVAStore()
    let motionManager = CMMotionManager()
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        inStore.paymentQueue(queue, updatedTransactions: transactions)
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        inStore.paymentQueueRestoreCompletedTransactionsFinished(queue)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        inStore.paymentQueue(queue, restoreCompletedTransactionsFailedWithError: error)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return inStore.paymentQueue(queue, shouldAddStorePayment: payment, for: product)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SKPaymentQueue.default().add(self)
        
        try! AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
                
        if #available(iOS 11.0, *) {
            MVAMemory.isIphoneX = (window?.safeAreaInsets.bottom ?? 0) > CGFloat(0)
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        if let scene = (window?.rootViewController as? GameViewController)?.scene {
            if scene.gameStarted && scene.intel.stop == false {
                scene.pauseGame(withAnimation: true)
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        SKPaymentQueue.default().remove(self)
    }

}
