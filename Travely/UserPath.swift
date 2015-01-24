//
//  UserPath.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/16.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import CoreData

@objc(UserPath)

class UserPath: NSManagedObject {
    
    @NSManaged var activityColorHex: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var timestamp: NSDate?
    
}
