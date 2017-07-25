//
//  MVAGameCenterHelper.swift
//  unPredictable
//
//  Created by Mike on 21/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import GameKit

class MVAGameCenterHelper: NSObject, GKGameCenterControllerDelegate {
    var authenticationViewController: UIViewController?
    private let gameCenterViewController = GKGameCenterViewController()
    
    static let authenticationCompleted = Notification.Name(rawValue: "AuthComp")
    static let toggleGCBtt = Notification.Name(rawValue: "toggleGCB")
    
    func authenticateLocalPlayer() {
        let localPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = { (viewController, error) in
            if viewController != nil {
                self.authenticationViewController = viewController
                NotificationCenter.default.post(name: MVAGameCenterHelper.authenticationCompleted, object: nil)
            }
        }
    }
    
    func reportDistance(_ dist: Double, errorHandler: ((Error?)->Void)? = nil) {
        guard GKLocalPlayer.localPlayer().isAuthenticated else { return }
        let gkScore = GKScore(leaderboardIdentifier: "com.mva.unpredictable.distance_traveled")
        if Locale.current.usesMetricSystem {
            // dist in KM
            gkScore.value = Int64(dist*10)
        } else {
            // dist in MI convert to KM bc leaderboards are in KM
            gkScore.value = Int64(MVAWorldConverter.milesToKilometers(dist)*10)
        }
        GKScore.report([gkScore], withCompletionHandler: errorHandler)
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    func showGKGameCenterViewController(viewController: UIViewController) {
        if GKLocalPlayer.localPlayer().isAuthenticated {
            gameCenterViewController.gameCenterDelegate = self
            viewController.present(gameCenterViewController,
                                   animated: true, completion: nil)
        }
    }
}
