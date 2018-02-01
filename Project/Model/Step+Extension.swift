//
//  Step+Extension.swift
//  Taylor
//
//  Created by Kevin on 06/02/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import UIKit

extension Step {
    
    class func getSet(ofWeek isWeek: Bool) -> [TimeInterval:Int32] {
        var set = [TimeInterval:Int32]()
        let calendar = Calendar.current
        let now = Date()
        var range: CountableRange<Int> = 0..<1
        if isWeek {
            // Get day range of this week
            if let weekRange = calendar.range(of: .weekday, in: .month, for: now) {
                range = weekRange.lowerBound..<weekRange.upperBound
            }
        } else {
            // Get day range of this month
            if let monthRange = calendar.range(of: .day, in: .month, for: now) {
                range = monthRange.lowerBound..<monthRange.upperBound
            }
        }
        // Get first date within the range
        var firstDay = calendar.date(from: calendar.dateComponents([.year,.month,], from: now)) ?? now
        if isWeek {
            firstDay = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear,.weekOfYear], from: now)) ?? now
        }
        for index in range {
            if let date = calendar.date(byAdding: .day, value: index-1, to: firstDay) {
                //Get last step of each date
                let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:
                    [NSPredicate.init(format: "year = %d", calendar.component(.year, from: date)),
                     NSPredicate.init(format: "month = %d", calendar.component(.month, from: date)),
                     NSPredicate.init(format: "day = %d", calendar.component(.day, from: date))])
                if let step = Step.mr_findFirst(with: predicate, sortedBy: "date", ascending: false) {
                    set[date.timeIntervalSince1970] = step.steps
                } else {
                    set[date.timeIntervalSince1970] = 0
                }
            }
        }
        log.debug(set)
        return set
    }
    
}
