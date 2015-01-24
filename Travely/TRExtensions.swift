//
//  Extensions.swift
//  Travely
//
//  Created by yuichiro_t on 2014/11/18.
//  Copyright (c) 2014年 Yuichiro Takahashi. All rights reserved.
//

import Foundation

extension Optional {
    func foreach(function: T -> Void) {
        if let some = self {
            function(some)
        }
    }
    
    func getOrElse(something: T) -> T {
        switch self {
        case .Some(let some): return some
        case .None: return something
        }
    }
}

extension Array {
    func foreach(f: T -> ()) {
        for some in self {
            f(some)
        }
    }
    
    mutating func removeObjectExceptingLast() -> Array {
        let lastItemIndex = self.count - 1
        self.removeRange(0..<lastItemIndex)
        
        return self
    }
    
    mutating func removeHead() -> Array {
        self.removeAtIndex(0)
        
        return self
    }
}

extension String {
    func toIntAsUnwrapOpt() -> Int {
        return self.toInt().getOrElse(0)
    }
    
    func toNSString() -> NSString {
        return self as NSString
    }
}

extension NSDate {
    func toString(format: String) -> String {
        let dateFormatter = NSDateFormatter()
        let outputDateFormatterStr = format
        dateFormatter.timeZone = NSTimeZone.defaultTimeZone()
        dateFormatter.dateFormat = outputDateFormatterStr
        return dateFormatter.stringFromDate(self)
    }
}

extension UIColor {
    class func hex2UIColor(hexColor: UInt, alpha: CGFloat) -> UIColor {
        let r = CGFloat((hexColor & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hexColor & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(hexColor & 0x0000FF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: alpha)
    }
}

class TRExtensions: NSObject {
    
}
