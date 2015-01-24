//
//  TRUtils.swift
//  Travely
//
//  Created by yuichiro_t on 2014/11/18.
//  Copyright (c) 2014年 Yuichiro Takahashi. All rights reserved.
//

import CoreMotion

class TRUtils: NSObject {
    
    private class var storyBoard: UIStoryboard {
        return UIStoryboard(name: "Main", bundle: nil)
    }
    
    class func getViewController(name: String) -> UIViewController {
        let sb  = self.storyBoard
        
        switch sb.instantiateViewControllerWithIdentifier(name) as? UIViewController {
        case .Some(let vc): return vc
        case .None: return UIViewController()
        }
        
    }
    
    class func getColorHexWithActivity(activty: CMMotionActivity?) -> UInt {
        switch activty {
        case .Some(let activity) where activity.stationary: return TRDrawUtils.hexColorBlue
        case .Some(let activity) where activity.walking:    return TRDrawUtils.hexColorGreen
        case .Some(let activity) where activity.running:    return TRDrawUtils.hexColorYellow
        case .Some(let activity) where activity.cycling:    return TRDrawUtils.hexColorOrange
        case .Some(let activity) where activity.automotive: return TRDrawUtils.hexColorRed
        default:                                            return TRDrawUtils.hexColorGray
        }
    }
    
    class func getColorHexWithUserPath(path: UserPath) -> UInt {
        return UInt(path.activityColorHex.getOrElse(NSNumber(unsignedLong: TRDrawUtils.hexColorGray)).intValue)
    }
}
