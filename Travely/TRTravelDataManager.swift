//
//  TRTravelDataManager.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/25.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import CoreData
import CoreLocation

class TRTravelDataManager: NSObject {
    
    private let coreDataManager: TRDefaultCoreDataManager!
    
    private let kStoreName = "Travely"
    private let kEntityNameUserPath = "UserPath"
    
    // MARK: - singleton pattern
    class var sharedManager: TRTravelDataManager {
        struct Singleton {
            static let instance = TRTravelDataManager()
        }
        return Singleton.instance
    }

    // MARK: - initialize
    private override init() {
        super.init()
        self.coreDataManager = TRDefaultCoreDataManager(storeName: kStoreName)
    }
    
    // MARK: - entity access method
    func getAllUserPath() -> [UserPath]? {
       return self.coreDataManager.fetch(kEntityNameUserPath, sortKey: nil, limit: 0) as? [UserPath]
    }
    
    func getAllSortedUserPath(sortKey: String) -> [UserPath]? {
        return self.coreDataManager.fetch(kEntityNameUserPath, sortKey: sortKey, limit: 0) as? [UserPath]
    }
    
    func insertUserPath(lm: UserLocateMotion, activityColorHex: UInt) {
        let userPath = self.coreDataManager.entityForInsert(kEntityNameUserPath) as UserPath
        userPath.longitude = lm.location.coordinate.longitude
        userPath.latitude = lm.location.coordinate.latitude
        userPath.timestamp = lm.location.timestamp
        userPath.activityColorHex = activityColorHex
        self.coreDataManager.saveContext()
    }
    
    func deleteAllUserPath() {
        self.coreDataManager.deleteAllData(kEntityNameUserPath)
    }
    
    func saveContext() {
        self.coreDataManager.saveContext()
    }
}
