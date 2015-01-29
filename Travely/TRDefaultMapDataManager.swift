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
    private let kSortKeyCD = "cd"
    
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
    func getRegions() -> [Region] {
        return self.coreDataManager.fetchWithSortKey(kEntityNameRegion, sortKey: kSortKeyCD, limit: 0,
            ascEnding: true) as [Region]
    }
    
    func getRegionsName() -> [String] {
        return getRegions().map { region -> String in region.name.getOrElse(self.kDefaultPlaceName) }
    }
    
    func getPrefectureNames() -> [String] {
        let prefectures = self.coreDataManager.fetchWithSortKey(kEntityNamePrefecture, sortKey: kSortKeyCD,
            limit: 0, ascEnding: true) as [Prefecture]
        return prefectures.map { pref -> String in pref.name.getOrElse("noname") }
    }
    
    func getLargeAreasName() -> [String] {
        let lAreas = self.coreDataManager.fetchWithSortKey(kEntityNameLargeArea, sortKey: kSortKeyCD,
            limit: 0, ascEnding: true) as [LargeArea]
        return lAreas.map { lArea -> String in lArea.name.getOrElse("nonae") }
    }
    
    func getPrefecturesNameWithRegionName(regionName: String) -> [String] {
        let prefectures = self.coreDataManager.fetchWithSortKey(kEntityNamePrefecture, sortKey: kSortKeyCD, limit: 0, ascEnding: true) as [Prefecture]
        
        return prefectures.filter { pref -> Bool in pref.region!.name! == regionName }.map { pref -> String in
            pref.name.getOrElse(self.kDefaultPlaceName)
        }
    }
    
    func getLargeAreaNameWithPrefectureName(prefectureName: String) -> [String] {
        let largeAreas = self.coreDataManager.fetchWithSortKey(kEntityNameLargeArea, sortKey: kSortKeyCD, limit: 0, ascEnding: true) as [LargeArea]
        
        return largeAreas.filter { lArea -> Bool in lArea.prefecture!.name! == prefectureName }.map { lArea -> String in
            lArea.name.getOrElse(self.kDefaultPlaceName)
        }
    }
    
    func getSmallAreaNameWithLargeAreaName(lAreaName: String) -> [String] {
        let smallArea = self.coreDataManager.fetchWithSortKey(kEntityNameSmallArea, sortKey: kSortKeyCD, limit: 0,
            ascEnding: true) as [SmallArea]
        
        return smallArea.filter { sArea -> Bool in sArea.largearea!.name! == lAreaName }.map { sArea -> String in
            sArea.name.getOrElse(self.kDefaultPlaceName)
        }
    }
    
    func insertMapData(areaJson: JSON) {
        self.coreDataManager.asyncInsertBlock {
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
