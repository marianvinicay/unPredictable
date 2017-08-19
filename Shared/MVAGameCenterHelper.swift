//
//  MVAGameCenterHelper.swift
//  unPredictable
//
//  Created by Mike on 21/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import GameKit
import UIKit

enum MVAAchievements {
    static let firstCrash: String = "com.mva.unpredictable.first_Crash"
    static let aroundEarth: String = "com.mva.unpredictable.around_Earth"
    static let crashed100Cars: String = "com.mva.unpredictable.100C_cars"
    static let marathon: String = "com.mva.unpredictable.marathon"
}

class MVAGameCenterHelper: NSObject {
    var authenticationViewController: GKGameCenterViewController?
    
    static let authenticationCompleted = Notification.Name(rawValue: "AuthComp")
    static let toggleBtts = Notification.Name(rawValue: "toggleBtts")
    
    override init() {
        super.init()
        //NotificationCenter.default.addObserver(self, selector: #selector(authDidChange), name: Notification.Name.GKPlayerAuthenticationDidChangeNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(authDidChange), name: NSNotification.Name(rawValue: GKPlayerAuthenticationDidChangeNotificationName), object: nil)
    }
    
    func authDidChange() {
        MVAMemory.enableGameCenter = GKLocalPlayer.localPlayer().isAuthenticated
    }
    
    func authenticateLocalPlayer(_ comp: @escaping ((Bool)->())) {
        let localPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = { (viewController: UIViewController?, error: Error?) in
            if viewController != nil {
                self.authenticationViewController = viewController as? GKGameCenterViewController
                NotificationCenter.default.post(name: MVAGameCenterHelper.authenticationCompleted, object: nil)
            } else if localPlayer.isAuthenticated {
                MVAMemory.enableGameCenter = true
                comp(true)
            } else {
                MVAMemory.enableGameCenter = false
                comp(false)
            }
        }
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
        ach.percentComplete = 100.0
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
        
        func showGKGameCenterViewController(viewController: UIViewController, withCompletion comp: @escaping ((Bool)->())) {
            if GKLocalPlayer.localPlayer().isAuthenticated {
                let gameCenterViewController = GKGameCenterViewController()
                gameCenterViewController.gameCenterDelegate = self
                viewController.present(gameCenterViewController,
                                       animated: true, completion: nil)
            } else {
                authenticateLocalPlayer(comp)
            }
        }
    }
#endif
