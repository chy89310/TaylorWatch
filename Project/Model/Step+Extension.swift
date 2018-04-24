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
        let today = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) ?? Date()
        /* get the step set in last week or last month */
        let firstDay = calendar.date(byAdding: isWeek ? .weekOfYear : .month, value: -1, to: today) ?? Date()
        let first = calendar.dateComponents([.day], from: today, to: firstDay).day ?? 0
        for index in first...0 {
            if let date = calendar.date(byAdding: .day, value: index, to: today) {
                //Get last step of each date
                let twelvehours: Double = 60*60*24
                let steps = step(for: date)
                set[date.timeIntervalSince1970+twelvehours] = steps
                log.debug("\(date):\(steps)")
            }
        }
        /* get the step set in the range of week or month
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
                let twelvehours: Double = 60*60*24
                set[date.timeIntervalSince1970+twelvehours] = step(for: date)
            }
        }
        log.debug(set)
        */
        return set
    }
    
    class func step(for date: Date) -> Int32 {
        let calendar = Calendar.current
        return SBManager.share.peripherals.filter({ (p) -> Bool in
            return p.state == .connected
        }).map({ (p) -> Int32 in
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:
                [NSPredicate(format: "year = %d", calendar.component(.year, from: date)),
                 NSPredicate(format: "month = %d", calendar.component(.month, from: date)),
                 NSPredicate(format: "day = %d", calendar.component(.day, from: date)),
                 NSPredicate(format: "device.uuid = %@", p.identifier.uuidString)])
            return Step.mr_findFirst(with: predicate, sortedBy: "date", ascending: false)?.steps ?? 0
        }).reduce(0, { (result, step) -> Int32 in
            return result + step
        })
    }
    
}
