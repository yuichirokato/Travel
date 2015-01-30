//
//  TRCreateTravelModel.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/28.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import UIKit

class TRCreateTravelModel: NSObject {
    
    private class var defaultMapDataManager: TRDefaultMapDataManager {
        return TRDefaultMapDataManager.sharedManager
    }
    
    private class var travelDataManger: TRTravelDataManager {
        return TRTravelDataManager.sharedManager
    }
    
    class func regions2TRTreeViewDataModel() -> [TRTreeViewDataModel] {
        return self.defaultMapDataManager.getRegionsName().map { name -> TRTreeViewDataModel in
            TRTreeViewDataModel(name: name, children: self.prefectures2TRTreeViewDataModel(name))
        }
    }
    
    class func prefectures2TRTreeViewDataModel(regionName: String) -> [TRTreeViewDataModel] {
        return self.defaultMapDataManager.getPrefecturesNameWithRegionName(regionName).map {
            prefName -> TRTreeViewDataModel in
            TRTreeViewDataModel(name: prefName, children: [TRTreeViewDataModel(name: "nil", children: nil)])
        }
    }
    
    class func largeAreas2TRTreeViewDataModel(prefName: String) -> [TRTreeViewDataModel] {
        return self.defaultMapDataManager.getLargeAreaNameWithPrefectureName(prefName).map {
            lAreaName -> TRTreeViewDataModel in
            TRTreeViewDataModel(name: lAreaName, children: self.smallAreas2TRTreeViewDataModel(lAreaName))
        }
    }
    
    class func smallAreas2TRTreeViewDataModel(lAreaName: String) -> [TRTreeViewDataModel] {
        return self.defaultMapDataManager.getSmallAreaNameWithLargeAreaName(lAreaName).map {
            sAreaName -> TRTreeViewDataModel in
            TRTreeViewDataModel(name: sAreaName, children: [TRTreeViewDataModel(name: "nil", children: nil)])
        }
    }
    
    class func insertTravel(pref: String, detailArea: String, departureDate: String, returnDate: String) {
        self.travelDataManger.insertTravel(pref, detailArea: detailArea, departureDate: departureDate, returnDate: returnDate)
    }

}
