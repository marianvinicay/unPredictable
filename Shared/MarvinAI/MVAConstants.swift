//
//  MVAConstants.swift
//  (un)Predictable
//
//  Created by Majo on 29/06/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import Foundation
import CoreGraphics

enum MVAConstants {
    static let basePlayerSpeed: Int = 200
    static let baseSpawnTime: TimeInterval = 2.4
    static let baseCarSize = CGSize(width: 50.0, height: 100.0)
    static let priorityTime: Double = 2.5
    static var baseBotSpeed: Int {
        return Int(arc4random_uniform(50)+80)
    }
}
