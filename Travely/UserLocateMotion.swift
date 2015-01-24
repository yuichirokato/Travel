//
//  UserLocateMotion.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/16.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion

class UserLocateMotion: NSObject {
    
    let location: CLLocation
    let activity: CMMotionActivity?
    
    init(location: CLLocation, activity: CMMotionActivity?) {
        self.location = location
        self.activity = activity
    }
    
    func isSameActivity(lm: UserLocateMotion) -> Bool {
        if let ac = self.activity {
            if ac.stationary  == lm.activity!.stationary &&
                ac.walking    == lm.activity!.walking &&
                ac.running    == lm.activity!.running &&
                ac.cycling    == lm.activity!.cycling &&
                ac.automotive == lm.activity!.automotive &&
                ac.unknown    == lm.activity!.unknown {
                    return true
            }
        }
        return false
    }
}
