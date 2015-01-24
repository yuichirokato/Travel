//
//  SmallArea.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/24.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import Foundation
import CoreData

@objc(SmallArea)

class SmallArea: NSManagedObject {

    @NSManaged var cd: NSNumber?
    @NSManaged var name: String?
    @NSManaged var largearea: LargeArea?

}
