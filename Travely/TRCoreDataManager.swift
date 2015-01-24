//
//  CoreDataManager.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/16.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class TRCoreDataManager: NSObject {
   
    private let managedObjectContext: NSManagedObjectContext!
    let kEntityName = "UserPath"
    
    // MARK: - singleton pattern
    class var sharedManager: TRCoreDataManager {
        struct Singleton {
            static let instance = TRCoreDataManager()
        }
        return Singleton.instance
    }
    
    // MARK: - initialize
    private override init() {
        super.init()
        self.managedObjectContext = createManagedObjectContext()
    }
    
    // MARK: - Entity access method
    func getAll(entityName: String) -> [UserPath]? {
        return self.fetch(entityName, sortKey: nil, limit: 0) as? [UserPath]
    }
    
    func getAllWithSortKey(entityName: String, sortKey: String) -> [NSManagedObject] {
        return self.fetch(entityName, sortKey: sortKey, limit: 0)
    }
    
    func addData(lm: UserLocateMotion, activityColorHex: UInt) {
        let userPath = entityForInsert(kEntityName) as UserPath
        userPath.longitude = lm.location.coordinate.longitude
        userPath.latitude = lm.location.coordinate.latitude
        userPath.timestamp = lm.location.timestamp
        userPath.activityColorHex = activityColorHex
        saveContext()
    }
    
    func deleteDataAtIndexPath(indexPath: NSIndexPath, entityName: String, sortKey: String) {
        let request = createFetchRequest(entityName, sortKey: sortKey, limit: 0)
        let resultsController = createFetchedResultsController(request)
        
        let pathData = resultsController.objectAtIndexPath(indexPath) as UserPath
    }
    
    func deleteAllData(entityName: String) {
        let deleteRequest = createFetchRequest(entityName, sortKey: nil, limit: 0)
        var error: NSError?
        let datas = self.managedObjectContext.executeFetchRequest(deleteRequest, error: &error) as [NSManagedObject]
        
        datas.foreach { self.managedObjectContext.deleteObject($0) }
        
        var saveError: NSError?
        managedObjectContext.save(&saveError)
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
        
        if context.hasChanges && !context.save(&error) {
            self.errorHandler(error!)
        }
        let pathData = getAll(kEntityName)
        
        pathData?.foreach { path in
            NSLog("user path value: \(path.longitude!)\n \(path.latitude!)\n \(path.activityColorHex)\n \(path.timestamp)")
        }
    }
    
    // MARK: - core data preparation method
    private func createManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = createPersistentStoreCoordinater()
        return managedObjectContext
    }
    
    private func createManagedObjectModel() -> NSManagedObjectModel {
        let url = NSBundle.mainBundle().URLForResource("Travely", withExtension: "momd")
        let managedObjectModel = NSManagedObjectModel(contentsOfURL: url!)
        return managedObjectModel!
    }
    
    private func createPersistentStoreCoordinater() -> NSPersistentStoreCoordinator {
        let storeUrl = self.applicationDocumentDirectory().URLByAppendingPathComponent("Travely.sqlite")
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
    
}
