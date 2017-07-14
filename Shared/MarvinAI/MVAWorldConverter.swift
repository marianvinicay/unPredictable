//
//  MVAWorldConverter.swift
//  (un)Predictable
//
//  Created by Majo on 28/06/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import Foundation

struct MVAWorldConverter {
    static func distanceToOdometer(_ dist: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = nil
        formatter.decimalSeparator = "."
        formatter.numberStyle = .decimal
        formatter.maximumIntegerDigits = 3
        formatter.minimumIntegerDigits = 3
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        return formatter.string(from: NSNumber(value: dist))!//String(dist.roundTo(NDecimals: 1))
    }
}
