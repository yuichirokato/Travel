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
    private let kEntityNameTravel = "Travel"
    private let kEntityNameTravelPoint = "TravelPoint"
    
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
        self.coreDataManager.asyncInsertBlock {
            let userPath = self.coreDataManager.entityForInsert(self.kEntityNameUserPath) as UserPath
            userPath.longitude = lm.location.coordinate.longitude
            userPath.latitude = lm.location.coordinate.latitude
            userPath.timestamp = lm.location.timestamp
            userPath.activityColorHex = activityColorHex
        }
    }
    
    func insertTravel(pref: String, detailArea: String, departureDate: String, returnDate: String) {
        self.coreDataManager.asyncInsertBlock {
            let travel = self.coreDataManager.entityForInsert(self.kEntityNameTravel) as Travel
            travel.destinationPrefecture = pref
            travel.destinationDetail = detailArea
            travel.departureDate = departureDate
            travel.returnDate = returnDate
        }
    }
    
    func insertTravelPoint(longitude: Double, latitude: Double, name: String, imageUrl: String?, timestamp: String, comment: String?) {
        self.coreDataManager.asyncInsertBlock {
            let travelPoint = self.coreDataManager.entityForInsert(self.kEntityNameTravelPoint) as TravelPoint
            travelPoint.longitude = longitude
            travelPoint.latitude = latitude
            travelPoint.placeName = name
            travelPoint.imageUrl = imageUrl
            travelPoint.timestamp = timestamp
            travelPoint.comment = comment
        }
    }
    
    func deleteAllUserPath() {
        self.coreDataManager.deleteAllData(kEntityNameUserPath)
    }
    
    func saveContext() {
        self.coreDataManager.saveContext()
    }
}
