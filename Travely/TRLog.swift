//
//  TRLog.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/16.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import UIKit

class TRLog: NSObject {
    class func log(message: String, file: String = __FILE__, function: String = __FUNCTION__) {
        NSLog("[%@: %@] %@", getFileName(file), function, message)
    }
    
    private class func getFileName(path: String, defName: String = "Default.swift") -> String {
        return path.rangeOfString("[^/]*$", options: .RegularExpressionSearch).map { path.substringWithRange($0) } ?? defName
    }

}
