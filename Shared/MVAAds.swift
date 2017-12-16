//
//  MVAAds.swift
//  unPredictable
//
//  Created by Majo on 09/08/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import Foundation

enum MVAAdsCombination {//: CustomStringConvertible {
    case onlyVideo, videoAndShort, onlyShort
    
    /*var description: String {
     switch self {
     case .onlyShort: return "OS"
     case .onlyVideo: return "OV"
     case.videoAndShort: return "VS"
     }
     }*/
}

#if os(iOS) || os(tvOS)
import GoogleMobileAds

class MVAAds: NSObject, GADRewardBasedVideoAdDelegate, GADInterstitialDelegate {
    class func prepareRewardAd() {
        if GADRewardBasedVideoAd.sharedInstance().isReady == false {
            let request = GADRequest()
            //request.testDevices = [kGADSimulatorID,"c793525e0543ad11207fc96a962b3fcf"]
            GADRewardBasedVideoAd.sharedInstance().load(request, withAdUnitID: "ca-app-pub-3670763804809001/6616246331")
        }
    }
    
    func prepareShortAd() {
        intAd = GADInterstitial(adUnitID: "ca-app-pub-3670763804809001/9699551155")
        intAd.delegate = self
        let request = GADRequest()
        //request.testDevices = [kGADSimulatorID,"c793525e0543ad11207fc96a962b3fcf"]
        intAd.load(request)
    }
    
    private var intAd: GADInterstitial!
    private var showShort = false
    
    private let config: MVAAdsCombination
    var successHandler: ((Bool)->())!
    var completionHandler: (()->())!
    
    init(config: MVAAdsCombination) {
        self.config = config
        super.init()
        if self.config == .onlyShort {
            self.prepareShortAd()
        } else {
            GADRewardBasedVideoAd.sharedInstance().delegate = self
        }
    }
    
    private func presentError(withName name: String = "Ad can't be loaded") {
        self.completionHandler()
        if config == .onlyShort {
            self.successHandler(false)
        } else {
            let alert = UIAlertController(title: "Sorry",
                                          message: name,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_: UIAlertAction) in
                self.successHandler(false)
            }))
            UIApplication.shared.keyWindow!.rootViewController!.present(alert, animated: true, completion: nil)
        }
    }
    
    func showAd(fromViewController viewController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!) {
        switch config {
        case .onlyVideo:
            if GADRewardBasedVideoAd.sharedInstance().isReady {
                completionHandler()
                GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: viewController)
            } else {
                presentError()
                MVAAds.prepareRewardAd()
            }
        case .videoAndShort:
            if GADRewardBasedVideoAd.sharedInstance().isReady {
                GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: viewController)
            } else {
                prepareShortAd()
            }
        case .onlyShort:
            if intAd.isReady == true {
                completionHandler()
                intAd.present(fromRootViewController: viewController)
            } else {
                showShort = true
            }
        }
    }
    
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        presentError(withName: error.localizedDescription)
        if config != .onlyShort {
            MVAAds.prepareRewardAd()
        }
    }
    
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        if config == .videoAndShort || showShort {
            completionHandler()
            intAd.present(fromRootViewController: UIApplication.shared.keyWindow!.rootViewController!)
        }
    }
    
    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        completionHandler()
        successHandler(true)
        MVAAds.prepareRewardAd()
    }
    
    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
        completionHandler()
        successHandler(true)
        MVAAds.prepareRewardAd()
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        completionHandler()
        successHandler(true)
        MVAAds.prepareRewardAd()
    }
    
    func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        completionHandler()
        successHandler(false)
        MVAAds.prepareRewardAd()
    }
    
    func rewardBasedVideoAdWillLeaveApplication(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        completionHandler()
        successHandler(true)
        MVAAds.prepareRewardAd()
    }
}
#else
    class MVAAds {
        var successHandler: ((Bool)->())!
        var completionHandler: (()->())!
        
        class func prepareRewardAd() {}
        init(config: MVAAdsCombination) {}
        func prepareShortAd() {}
        func showAd() {}
    }
#endif
