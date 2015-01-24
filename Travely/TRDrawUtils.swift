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
    
    class func getActivityColor(activity: CMMotionActivity?) -> UIColor {
        switch activity {
        case .Some(let activity) where activity.stationary: return UIColor.blueColor()
        case .Some(let activity) where activity.walking:    return UIColor.greenColor()
        case .Some(let activity) where activity.running:    return UIColor.yellowColor()
        case .Some(let activity) where activity.cycling:    return UIColor.orangeColor()
        case .Some(let activity) where activity.automotive: return UIColor.redColor()
        default:                                            return UIColor.grayColor()
        }
    }
    
    class func getActivityColorWithHex(hexColor: UInt?) -> UIColor {
        switch hexColor {
        case .Some(let colorCode): return UIColor.hex2UIColor(colorCode, alpha: 1.0)
        case .None: return UIColor.grayColor()
        }
    }
    
}
