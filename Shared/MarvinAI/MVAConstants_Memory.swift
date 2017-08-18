//
//  MVAConstants.swift
//  (un)Predictable
//
//  Created by Majo on 29/06/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import Foundation
import CoreGraphics
#if os(iOS)
    import UIKit
#endif

enum MVAConstants {
    static let basePlayerSpeed: Int = 200
    static let baseSpawnTime: TimeInterval = 2.2
    #if os(iOS)
    static var baseCarSize: CGSize {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad: return CGSize(width: 80.0, height: 144.0)
        default: return CGSize(width: 50.0, height: 90.0)
        }
    }
    #elseif os(watchOS)
        static let baseCarSize = CGSize(width: 20.0, height: 36.0)
    #elseif os(macOS)
        static let baseCarSize = CGSize(width: 80.0, height: 144.0)
    #endif
    static let priorityTime: Double = 1.8
    static var baseBotSpeed: Int {
        return Int(arc4random_uniform(50))+MVAConstants.minimalBotSpeed
    }
    static let minimalBotSpeed: Int = 60
    static let maxBotSpeed: Int = 110
}

enum MVAMemory {
    static var tutorialDisplayed: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "tutDisp")
        }
        get {
            return UserDefaults.standard.value(forKey: "tutDisp") as? Bool ?? false
        }
    }
    
    static var audioMuted: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "audioM")
        }
        get {
            return UserDefaults.standard.value(forKey: "audioM") as? Bool ?? false
        }
    }
    
    static var playerCar: String {
        set {
            UserDefaults.standard.set(newValue, forKey: "pCar")
        }
        get {
            return UserDefaults.standard.value(forKey: "pCar") as? String ?? MVACarNames.playerOrdinary
        }
    }
    
    static var ownedCars: [String] {
        set {
            UserDefaults.standard.set(newValue, forKey: "ownCars")
        }
        get {
            return UserDefaults.standard.value(forKey: "ownCars") as? [String] ?? [MVACarNames.playerOrdinary]
        }
    }
    
    static var adCars: [String] {
        set {
            UserDefaults.standard.set(newValue, forKey: "adCars")
        }
        get {
            return UserDefaults.standard.value(forKey: "adCars") as? [String] ?? []
        }
    }
    
    static var maxPlayerDistance: Double {
        set {
            UserDefaults.standard.set(newValue, forKey: "maxPDist")
        }
        get {
            return UserDefaults.standard.value(forKey: "maxPDist") as? Double ?? 0.0
        }
    }
    
    static var crashedCars: Int64 {
        set {
            UserDefaults.standard.set(newValue, forKey: "crashCars")
        }
        get {
            return UserDefaults.standard.value(forKey: "crashCars") as? Int64 ?? Int64(0)
        }
    }
    
    static var accumulatedDistance: Double {
        set {
            UserDefaults.standard.set(newValue, forKey: "accDist")
        }
        get {
            return UserDefaults.standard.value(forKey: "accDist") as? Double ?? 0.0
        }
    }
    
    static var adsEnabled: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "adsEn")
        }
        get {
            return UserDefaults.standard.value(forKey: "adsEn") as? Bool ?? false
        }
    }
    
    static var enableGameCenter: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "enGC")
        }
        get {
            return UserDefaults.standard.value(forKey: "enGC") as? Bool ?? true
        }
    }
}
