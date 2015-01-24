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
    
    private let managedObjectContext: NSManagedObjectContext!
    
    let kEntityNameRegion = "Region"
    let kEntityNamePrefecture = "Prefecture"
    let kEntityNameLargeArea = "LargeArea"
    let kEntityNameSmallArea = "SmallArea"
    let kJsonKeyName = "-name"
    let kJsonKeyCD = "-cd"
    let kJsonKeyRegion = "Region"
    let kJsonKeyPrefecture = "Prefecture"
    let kJsonKeyLargeArea = "LargeArea"
    let kJsonKeySmallArea = "SmallArea"
    
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
        self.managedObjectContext = createManagedObjectContext()
    }
    
    // MARK: - Entity access method
    func getAll(entityName: String) -> [Region]? {
        return self.fetch(entityName, sortKey: nil, limit: 0) as? [Region]
    }
    
    func getAllWithSortKey(entityName: String, sortKey: String) -> [NSManagedObject] {
        return self.fetch(entityName, sortKey: sortKey, limit: 0)
    }
    
    func addData(areaJson: JSON) {
        let region = entityForInsert(kEntityNameRegion) as Region
        
        region.cd = (areaJson[kJsonKeyRegion][kJsonKeyCD].string ?? "-1").toInt() ?? -1
        region.name = areaJson[kJsonKeyRegion][kJsonKeyName].string ?? "def"
        region.prefecture = parseJson2Prefecture(areaJson[kJsonKeyRegion][kJsonKeyPrefecture], region: region)
        saveContext()
    }
    
    func deleteAllData(entityName: String) {
        let deleteRequest = createFetchRequest(entityName, sortKey: nil, limit: 0)
        var error: NSError?
        let datas = self.managedObjectContext.executeFetchRequest(deleteRequest, error: &error) as [NSManagedObject]
        
        datas.foreach { self.managedObjectContext.deleteObject($0) }
        
        var saveError: NSError?
        self.managedObjectContext.save(&saveError)
    }
    
    func fetch(entityName: String, sortKey: String?, limit: Int) -> [NSManagedObject] {
        let context = self.managedObjectContext
        let request = self.createFetchRequest(entityName, sortKey: sortKey, limit: limit)
        var error: NSError?
        
        return context.executeFetchRequest(request, error: &error) as [NSManagedObject]
    }
    
    private func entityForInsert(entityName: String) -> NSManagedObject {
        let context = self.managedObjectContext
        let managedObject = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context) as NSManagedObject
        
        return managedObject
    }
    
    func saveContext() {
        var error: NSError?
        let context = self.managedObjectContext
        
        context.performBlock {
            if context.hasChanges && !context.save(&error) {
                self.errorHandler(error!)
            }
        }
    }
    
    // MARK: - core data preparation method
    
    private func createManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = createPersistentStoreCoordinater()
        return managedObjectContext
    }
    
    private func createManagedObjectModel() -> NSManagedObjectModel {
        let url = NSBundle.mainBundle().URLForResource("DefaultMapData", withExtension: "momd")
        let managedObjectModel = NSManagedObjectModel(contentsOfURL: url!)
        return managedObjectModel!
    }
    
    private func createPersistentStoreCoordinater() -> NSPersistentStoreCoordinator {
        let storeUrl = self.applicationDocumentDirectory().URLByAppendingPathComponent("DefaultMapData.sqlite")
        var error:NSError?
        
        let persistentStoreCoordinater = NSPersistentStoreCoordinator(managedObjectModel: createManagedObjectModel())
        let checkPersistent = persistentStoreCoordinater.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeUrl, options: nil, error: &error)
        
        switch checkPersistent {
        case .Some(let persistent):
            return persistentStoreCoordinater
        case .None:
            println("Unresolved error \(error!) \(error!.userInfo)")
            abort()
        }
    }
    
    private func createFetchedResultsController(request: NSFetchRequest) -> NSFetchedResultsController {
        let resultController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        var error: NSError?
        resultController.performFetch(&error)
        return resultController
    }
    
    private func createFetchRequest(entityName: String, sortKey: String?, limit: Int) -> NSFetchRequest {
        let request = NSFetchRequest()
        let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: self.managedObjectContext)
        
        request.entity = entity
        request.fetchLimit = limit
        
        request.sortDescriptors = sortKey.map({ key in return [NSSortDescriptor(key: key, ascending: false)]})
        
        return request
    }
    
    private func errorHandler(error: NSError) {
        println(error)
        NSLog("Unresolved error %@, %@", error, error.userInfo!)
        abort()
    }
    
    private func applicationDocumentDirectory() -> NSURL {
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last as NSURL
    }
    
    // MARK: - JSON Utils
    
    private func parseJson2Prefecture(json: JSON, region: Region) -> NSSet? {
        
        println("regionName = \(region.name!)")
        println("regionCD = \(region.cd!)")
        
        switch json.array {
        case .Some(let prefectures):
            return NSSet(array:
                prefectures.map { pref -> Prefecture in
                    let p = self.entityForInsert(self.kEntityNamePrefecture) as Prefecture
                    p.name = pref[self.kJsonKeyName].string ?? "def"
                    p.cd = (pref[self.kJsonKeyCD].string ?? "-1").toInt() ?? -1
                    p.largearea = self.parseJson2LargeArea(pref[self.kJsonKeyLargeArea], prefecture: p)
                    p.region = region
                    return p
                }
            )
        case .None:
            return NSSet(object: json.dictionary.map { prefecture -> Prefecture in
                let pref = self.entityForInsert(self.kEntityNamePrefecture) as Prefecture
                pref.name = prefecture[self.kJsonKeyName]?.string ?? "def"
                pref.cd = (prefecture[self.kJsonKeyCD]?.string ?? "-1").toInt() ?? -1
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
                    let lArea = self.entityForInsert(self.kEntityNameLargeArea) as LargeArea
                    lArea.name = la[self.kJsonKeyName].string ?? "def"
                    lArea.cd = (la[self.kJsonKeyCD].string ?? "-1").toInt() ?? -1
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
                let sArea = self.entityForInsert(self.kEntityNameSmallArea) as SmallArea
                sArea.name = sa[self.kJsonKeyName].string ?? "def"
                sArea.cd = (sa[self.kJsonKeyCD].string ?? "-1").toInt() ?? -1
                sArea.largearea = largeArea
                return sArea
                }
            )
        case .None:
            return NSSet(object: json.dictionary.map { sa -> SmallArea in
                let sArea = self.entityForInsert(self.kEntityNameSmallArea) as SmallArea
                sArea.name = sa[self.kJsonKeyName]?.string ?? "def"
                sArea.cd = (sa[self.kJsonKeyCD]?.string ?? "-1").toInt() ?? -1
                sArea.largearea = largeArea
                return sArea
                }!
            )
        }
    }
   
}
