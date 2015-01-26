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
    private let kDefaultPlaceName = "noname"
    
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
    
    func getRegions() -> [Region] {
        return self.coreDataManager.fetch(kEntityNameRegion, sortKey: nil, limit: 0) as [Region]
    }
    
    func gerRegionWithCD(cd: String) -> [Region] {
        let results = self.coreDataManager.fetchWithConditions(kEntityNameRegion, sortKey: nil, conditions: "cd = %@", condisonValus: cd)
        return results as [Region]
    }
    
    func getPrefecturesWithRegion(region: Region) -> [Prefecture] {
        if let prefectures = region.prefecture {
            return prefectures.allObjects as [Prefecture]
        }
        abort()
    }
    
    func getRegionsName() -> [String] {
        return getRegions().map { region -> String in region.name.getOrElse(self.kDefaultPlaceName) }
    }
    
    func getPrefecturesNameWithRegion(region: Region) -> [String] {
        return getPrefecturesWithRegion(region).map { pref -> String in pref.name.getOrElse(self.kDefaultPlaceName) }
    }
    
    func getPrefecturesNameWithRegionName(regionName: String) -> [String] {
        let prefectures = self.coreDataManager.fetch(kEntityNamePrefecture, sortKey: nil, limit: 0) as [Prefecture]
        return prefectures.filter { pref -> Bool in pref.region!.name! == regionName }.map { pref -> String in
            pref.name.getOrElse(self.kDefaultPlaceName)
        }
    }
    
    func getLargeAreasNameWithPrefecture(prefecture: Prefecture) -> [String] {
        let largeAreas = prefecture.largearea!.allObjects as [LargeArea]
        return largeAreas.map { lArea -> String in lArea.name.getOrElse(self.kDefaultPlaceName) }
    }
    
    func getSmallAreasNameWithLargeArea(lArea: LargeArea) -> [String] {
        let smallArea = lArea.smallarea!.allObjects as [SmallArea]
        return smallArea.map { sArea -> String in sArea.name.getOrElse(self.kDefaultPlaceName) }
    }
    
    func insertMapData(areaJson: JSON) {
        self.coreDataManager.aysncInsertBlock {
            let region = self.coreDataManager.entityForInsert(self.kEntityNameRegion) as Region
            region.cd = areaJson[self.kJsonKeyRegion][self.kJsonKeyCD].string.getOrElse("-1").toIntAsUnwrapOpt()
            region.name = areaJson[self.kJsonKeyRegion][self.kJsonKeyName].string.getOrElse("def")
            region.prefecture = self.parseJson2Prefecture(areaJson[self.kJsonKeyRegion][self.kJsonKeyPrefecture],
                region: region)
        }
    }
    
    func saveContext() {
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
                    p.cd = pref[self.kJsonKeyCD].string.getOrElse("-1").toIntAsUnwrapOpt()
                    p.largearea = self.parseJson2LargeArea(pref[self.kJsonKeyLargeArea], prefecture: p)
                    p.region = region
                    return p
                }
            )
        case .None:
            return NSSet(object: json.dictionary.map { prefecture -> Prefecture in
                let pref = self.coreDataManager.entityForInsert(self.kEntityNamePrefecture) as Prefecture
                pref.name = prefecture[self.kJsonKeyName]?.string.getOrElse("def")
                pref.cd = prefecture[self.kJsonKeyCD]?.string.getOrElse("-1").toIntAsUnwrapOpt()
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
