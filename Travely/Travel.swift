//
//  Travel.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/30.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import Foundation
import CoreData

@objc(Travel)

class Travel: NSManagedObject {

    @NSManaged var departureDate: String?
    @NSManaged var returnDate: String?
    @NSManaged var destinationPrefecture: String?
    @NSManaged var destinationDetail: String?

}
