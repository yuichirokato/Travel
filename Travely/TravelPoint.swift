//
//  TravelPoint.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/30.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import Foundation
import CoreData

@objc(TravelPoint)

class TravelPoint: NSManagedObject {

    @NSManaged var longitude: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var imageUrl: String?
    @NSManaged var comment: String?
    @NSManaged var placeName: String?
    @NSManaged var timestamp: String?

}
