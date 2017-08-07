//
//  MVAGameCenterHelper.swift
//  unPredictable
//
//  Created by Mike on 21/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import GameKit
#if os(iOS) || os(tvOS)
    import UIKit
#endif

enum MVAAchievements {
    static let firstCrash: String = "com.mva.unpredictable.first_Crash"
    static let aroundEarth: String = "com.mva.unpredictable.around_Earth"
}

class MVAGameCenterHelper: NSObject {
    #if os(iOS) || os(tvOS) || os(macOS)
        var authenticationViewController: GKGameCenterViewController?
    #endif
    
    static let authenticationCompleted = Notification.Name(rawValue: "AuthComp")
    static let toggleBtts = Notification.Name(rawValue: "toggleBtts")
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(authDidChange), name: NSNotification.Name(rawValue: GKPlayerAuthenticationDidChangeNotificationName), object: nil)
    }
    
    func authDidChange() {
        MVAMemory.enableGameCenter = GKLocalPlayer.localPlayer().isAuthenticated
    }
    
    func authenticateLocalPlayer() {
        let localPlayer = GKLocalPlayer.localPlayer()
        #if os(iOS) || os(tvOS)
            localPlayer.authenticateHandler = { (viewController: UIViewController?, error: Error?) in
                if viewController != nil {
                    self.authenticationViewController = viewController as? GKGameCenterViewController
                    NotificationCenter.default.post(name: MVAGameCenterHelper.authenticationCompleted, object: nil)
                } else if localPlayer.isAuthenticated {
                    MVAMemory.enableGameCenter = true
                } else {
                    MVAMemory.enableGameCenter = false
                }
            }
        #elseif os(watchOS)
            localPlayer.authenticateHandler = { (error: Error?) in
                if localPlayer.isAuthenticated && error == nil {
                    MVAMemory.enableGameCenter = true
                } else {
                    MVAMemory.enableGameCenter = false
                }
            }
        #endif
    }
    
    func report(distance dist: Double) {
        guard GKLocalPlayer.localPlayer().isAuthenticated else { return }
        let gkScore = GKScore(leaderboardIdentifier: "com.mva.unpredictable.distance_traveled")
        if Locale.current.usesMetricSystem {
            // dist in KM
            gkScore.value = Int64(dist*10)
        } else {
            // dist in MI convert to KM bc leaderboards are in KM
            gkScore.value = Int64(MVAWorldConverter.milesToKilometers(dist)*10)
        }
        GKScore.report([gkScore], withCompletionHandler: nil)
    }
    
    func report(crashedCars numOfCars: Int64) {
        guard GKLocalPlayer.localPlayer().isAuthenticated else { return }
        let gkScore = GKScore(leaderboardIdentifier: "com.mva.unpredictable.crashed_cars")
        gkScore.value = numOfCars
        GKScore.report([gkScore], withCompletionHandler: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func report(achievement: String) {
        guard GKLocalPlayer.localPlayer().isAuthenticated else { return }
        let ach = GKAchievement(identifier: achievement)
        ach.showsCompletionBanner = true
        GKAchievement.report([ach], withCompletionHandler: nil)
    }
}
//???
#if os(iOS) || os(tvOS)
    extension MVAGameCenterHelper: GKGameCenterControllerDelegate {
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true, completion: nil)
        }
        
        func showGKGameCenterViewController(viewController: UIViewController) {
            if GKLocalPlayer.localPlayer().isAuthenticated {
                let gameCenterViewController = GKGameCenterViewController()
                gameCenterViewController.gameCenterDelegate = self
                viewController.present(gameCenterViewController,
                                       animated: true, completion: nil)
            } else {
                authenticateLocalPlayer()
            }
        }
    }
#endif
