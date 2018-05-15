//
//  AppDelegate.swift
//  (un)Predictable
//
//  Created by Majo on 25/08/16.
//  Copyright © 2016 MarVin. All rights reserved.
//
//AdMob adID = ca-app-pub-3670763804809001~8265381684

import UIKit
import AVFoundation
import Firebase
import GoogleMobileAds
import Fabric
import Crashlytics
import StoreKit
import CoreMotion

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SKPaymentTransactionObserver {
    
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

    var window: UIWindow?
    let inStore = MVAStore()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        SKPaymentQueue.default().add(self)
                
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
        Fabric.with([Crashlytics.self])
        FirebaseApp.configure()
        GADMobileAds.configure(withApplicationID: "ca-app-pub-3670763804809001~8265381684")
        MVAAds.prepareRewardAd()
        MVAPopup.customiseAppeareance()
        
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

    func applicationDidBecomeActive(_ application: UIApplication) {
        MVAAds.prepareRewardAd()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        SKPaymentQueue.default().remove(self)
        RKRobotDiscoveryAgent.disconnectAll()
    }


}

