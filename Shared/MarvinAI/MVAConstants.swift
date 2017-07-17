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
    static let baseSpawnTime: TimeInterval = 2.3
    #if os(iOS)
    static var baseCarSize: CGSize {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad: return CGSize(width: 90.0, height: 162.0)
        default: return CGSize(width: 50.0, height: 90.0)
        }
    }
    #else
    static let baseCarSize = CGSize(width: 50.0, height: 90.0)
    #endif
    static let priorityTime: Double = 2.5
    static var baseBotSpeed: Int {
        return Int(arc4random_uniform(50))+MVAConstants.minimalBotSpeed
    }
    static let minimalBotSpeed: Int = 60
}

enum MVAMemory {
    static var maxPlayerDistance: Double? {
        set {
            UserDefaults.standard.set(newValue, forKey: "maxPDist")
        }
        get {
            return UserDefaults.standard.value(forKey: "maxPDist") as? Double
        }
    }
}
