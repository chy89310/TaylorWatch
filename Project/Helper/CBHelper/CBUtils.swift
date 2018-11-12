//
//  CBUtils.swift
//  Taylor
//
//  Created by Connectz technology co., ltd on 11/2/2018.
//  Copyright © 2018 Connectz technology co., ltd. All rights reserved.
//

import Foundation

class CBUtils: NSObject {
    
    class func caloriesFrom(step: Int) -> Float {
        let calendar = Calendar.current
        let birthDay = Date(timeIntervalSince1970: UserDefaults.double(of: .birthday))
        let year = calendar.component(.year, from: Date()) - calendar.component(.year, from: birthDay)
        let  weight = UserDefaults.int(of: .weight) > 0 ? UserDefaults.int(of: .weight) : 60
        let height = UserDefaults.int(of: .height) > 0 ? UserDefaults.int(of: .height) : 170
        
        return caloriesFrom(isMale: UserDefaults.bool(of: .isMale), ageYear: year, weightKG: weight, heightCM: height, stepWalk: step, stepRun: 0)
    }
    
    class func caloriesFrom(isMale: Bool, ageYear: Int, weightKG: Int, heightCM: Int, stepWalk: Int, stepRun: Int) -> Float {
        // first calculate the BMR (Mifflin - St Jeor Formula)
        // https://www.freedieting.com/calorie_needs.html
        let weigthFactor = Float(10 * weightKG)
        let heightFactor = 6.25 * Float(heightCM)
        let yearFactor = 5 * ageYear
        var bmr = weigthFactor + heightFactor - Float(yearFactor) + (isMale ? 5 : -161)
        // the above is BMR per day, we need BMR per hour.
        bmr /= 24.0
        // then multiply by MET
        // https://www.hsph.harvard.edu/nutritionsource/mets-activity-table/
        // FIXME: assume walking = 2.5, running = 6.5
        // FIXME: i consider walking = 4000 steps/hr, and running = 8000 steps/hr.
        // FIXME: thus steps_walking / 4000 = 1hr walking, steps_running / 8000 = 1hr running.
        let cal_walking = bmr * 2.5 * Float(stepWalk) / 4000;
        let cal_running = bmr * 6.5 * Float(stepRun) / 8000;
        log.debug("Cals caculate: male(\(isMale)), age(\(ageYear)), weight(\(weightKG)), height(\(heightCM)), walk(\(stepWalk)), run(\(stepRun)), cals(\(cal_walking+cal_running))")
        return cal_walking + cal_running;

    }
    
}
