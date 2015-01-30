//
//  DrawUtils.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/16.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import CoreMotion

class TRDrawUtils: NSObject {
   
    class var hexColorRed:    UInt { return 0xff2a68 }
    class var hexColorOrange: UInt { return 0xff5e3a }
    class var hexColorYellow: UInt { return 0xffcd02 }
    class var hexColorGreen:  UInt { return 0x0bd318 }
    class var hexColorBlue:   UInt { return 0x1d62f0 }
    class var hexColorGray:   UInt { return 0xC7C7CC }
    
    class func getActivityColor(activity: CMMotionActivity?) -> UInt {
        switch activity {
        case .Some(let activity) where activity.stationary: return hexColorBlue
        case .Some(let activity) where activity.walking:    return hexColorGreen
        case .Some(let activity) where activity.running:    return hexColorYellow
        case .Some(let activity) where activity.cycling:    return hexColorOrange
        case .Some(let activity) where activity.automotive: return hexColorRed
        default:                                            return hexColorGray
        }
    }
    
    class func getActivityColorWithHex(hexColor: UInt?) -> UIColor {
        switch hexColor {
        case .Some(let colorCode): return UIColor.hex2UIColor(colorCode, alpha: 1.0)
        case .None: return UIColor.grayColor()
        }
    }
    
}
