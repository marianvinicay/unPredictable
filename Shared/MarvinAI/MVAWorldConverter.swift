//
//  MVAWorldConverter.swift
//  (un)Predictable
//
//  Created by Majo on 28/06/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import Foundation

struct MVAWorldConverter {
    static func pointsSpeedToRealWorld(_ spd: Int) -> Int {
        let kmH = spd/5
        if Locale.current.usesMetricSystem {
            return kmH
        } else {
            return Int(Double(kmH)*0.62)
        }
    }
    
    static func distanceToOdometer(_ dist: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = nil
        formatter.decimalSeparator = "."
        formatter.numberStyle = .decimal
        formatter.maximumIntegerDigits = 3
        formatter.minimumIntegerDigits = 3
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        return formatter.string(from: NSNumber(value: dist))!
    }
}
