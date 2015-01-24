//
//  TRDefaultMapDataManager.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/24.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import UIKit
import CoreData

class TRDefaultMapDataManager: NSObject {
    
    private let coreDataManager: TRDefaultCoreDataManager!
    
    private let kStoreName = "DefaultMapData"
    private let kEntityNameRegion = "Region"
    private let kEntityNamePrefecture = "Prefecture"
    private let kEntityNameLargeArea = "LargeArea"
    private let kEntityNameSmallArea = "SmallArea"
    private let kJsonKeyName = "-name"
    private let kJsonKeyCD = "-cd"
    private let kJsonKeyRegion = "Region"
    private let kJsonKeyPrefecture = "Prefecture"
    private let kJsonKeyLargeArea = "LargeArea"
    private let kJsonKeySmallArea = "SmallArea"
    
    // MARK: - singleton pattern
    class var sharedManager: TRDefaultMapDataManager {
        struct Singleton {
            static let instance = TRDefaultMapDataManager()
        }
        return Singleton.instance
    }
    
    // MARK: - initialize
    private override init() {
        super.init()
        self.coreDataManager = TRDefaultCoreDataManager(storeName: kStoreName)
    }
    
    // MARK: - entity access method
    func getAll(entityName: String) -> [Region]? {
        return self.coreDataManager.fetch(entityName, sortKey: nil, limit: 0) as? [Region]
    }
    
    func getAllWithSortKey(entityName: String, sortKey: String) -> [NSManagedObject] {
        return self.coreDataManager.fetch(entityName, sortKey: sortKey, limit: 0)
    }
    
    func insertMapData(areaJson: JSON) {
        let region = self.coreDataManager.entityForInsert(kEntityNameRegion) as Region
        
        region.cd = areaJson[kJsonKeyRegion][kJsonKeyCD].string.getOrElse("-1").toInt().getOrElse(-1)
        region.name = areaJson[kJsonKeyRegion][kJsonKeyName].string ?? "def"
        region.prefecture = parseJson2Prefecture(areaJson[kJsonKeyRegion][kJsonKeyPrefecture], region: region)
        self.coreDataManager.saveContext()
    }
    
    // MARK: - parse json to entity set
    private func parseJson2Prefecture(json: JSON, region: Region) -> NSSet? {
        
        switch json.array {
        case .Some(let prefectures):
            return NSSet(array:
                prefectures.map { pref -> Prefecture in
                    let p = self.coreDataManager.entityForInsert(self.kEntityNamePrefecture) as Prefecture
                    p.name = pref[self.kJsonKeyName].string.getOrElse("def")
                    p.cd = pref[self.kJsonKeyCD].string.getOrElse("-1").toInt().getOrElse(-1)
                    p.largearea = self.parseJson2LargeArea(pref[self.kJsonKeyLargeArea], prefecture: p)
                    p.region = region
                    return p
                }
            )
        case .None:
            return NSSet(object: json.dictionary.map { prefecture -> Prefecture in
                let pref = self.coreDataManager.entityForInsert(self.kEntityNamePrefecture) as Prefecture
                pref.name = prefecture[self.kJsonKeyName]?.string.getOrElse("def")
                pref.cd = prefecture[self.kJsonKeyCD]?.string.getOrElse("-1").toInt().getOrElse(-1)
                pref.largearea = self.parseJson2LargeArea(prefecture[self.kJsonKeyLargeArea]!, prefecture: pref)
                pref.region = region
                return pref
                }!
            )
        }
    }
    
    private func parseJson2LargeArea(json: JSON, prefecture: Prefecture) -> NSSet? {
        if let largeArea = json.array {
            return NSSet(array:
                largeArea.map { la -> LargeArea in
                    let lArea = self.coreDataManager.entityForInsert(self.kEntityNameLargeArea) as LargeArea
                    lArea.name = la[self.kJsonKeyName].string.getOrElse("def")
                    lArea.cd = la[self.kJsonKeyCD].string .getOrElse("-1").toInt().getOrElse(-1)
                    lArea.smallarea = self.parseJson2SmallArea(la[self.kJsonKeySmallArea],largeArea: lArea)
                    lArea.prefecture = prefecture
                    return lArea
                }
            )
        }
        println("parse failed in largearea")
        return .None
    }
    
    private func parseJson2SmallArea(json: JSON, largeArea: LargeArea) -> NSSet? {
        switch json.array {
        case .Some(let array):
            return NSSet(array: array.map { sa -> SmallArea in
                let sArea = self.coreDataManager.entityForInsert(self.kEntityNameSmallArea) as SmallArea
                sArea.name = sa[self.kJsonKeyName].string.getOrElse("def")
                sArea.cd = sa[self.kJsonKeyCD].string.getOrElse("-1").toInt().getOrElse(-1)
                sArea.largearea = largeArea
                return sArea
                }
            )
        case .None:
            return NSSet(object: json.dictionary.map { sa -> SmallArea in
                let sArea = self.coreDataManager.entityForInsert(self.kEntityNameSmallArea) as SmallArea
                sArea.name = sa[self.kJsonKeyName]?.string.getOrElse("def")
                sArea.cd = sa[self.kJsonKeyCD]?.string.getOrElse("-1").toInt().getOrElse(-1)
                sArea.largearea = largeArea
                return sArea
                }!
            )
        }
    }
}
