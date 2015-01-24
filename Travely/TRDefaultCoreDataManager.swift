//
//  TRDefaultCoreDataManager.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/24.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import CoreData

class TRDefaultCoreDataManager: NSObject {
    
    let parentContext: NSManagedObjectContext!
    let childContext: NSManagedObjectContext!
    
    // MARK: - initialize
    
    init(storeName: String) {
        super.init()
        self.parentContext = self.createParentManagedObjectContext(storeName)
        self.childContext = self.createChildManagedObjectContext(self.parentContext)
    }
    
    // MARK: - entity access method
    
    func entityForInsert(entityName: String) -> NSManagedObject {
        let managedObject = NSEntityDescription.insertNewObjectForEntityForName(entityName,
            inManagedObjectContext: self.childContext) as NSManagedObject
        
        return managedObject
    }
    
    func fetch(entityName: String, sortKey: String?, limit: Int) -> [NSManagedObject] {
        let request = self.createFetchRequest(entityName, sortKey: sortKey, limit: limit)
        var error: NSError?

        return self.childContext.executeFetchRequest(request, error: &error) as [NSManagedObject]
    }
    
    func deleteAllData(entityName: String) {
        let deleteRequest = self.createFetchRequest(entityName, sortKey: nil, limit: 0)
        var error: NSError?
        let datas = self.childContext.executeFetchRequest(deleteRequest, error: &error) as [NSManagedObject]
        
        datas.foreach { self.childContext.deleteObject($0) }
        self.saveContext()
    }

    func saveContext() {
        childContext.performBlock {
            var error: NSError?
            if self.childContext.hasChanges && !self.childContext.save(&error) {
                self.errorHandler(error!)
                return
            }
            self.saveParentContext()
        }
    }
    
    private func saveParentContext() {
        parentContext.performBlock {
            var error: NSError?
            if self.parentContext.hasChanges && !self.parentContext.save(&error) {
                self.errorHandler(error!)
            }
        }
    }
    
    // MARK: - core data preparation method
    private func createParentManagedObjectContext(storeName: String) -> NSManagedObjectContext {
        let parentManagedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        parentManagedObjectContext.persistentStoreCoordinator = createPersistentStoreCoordinater(storeName)
        return parentManagedObjectContext
    }
    
    private func createChildManagedObjectContext(parentContext: NSManagedObjectContext) -> NSManagedObjectContext {
        let childManagedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        childManagedObjectContext.parentContext = parentContext
        return childManagedObjectContext
    }
    
    private func createManagedObjectModel(storeName: String) -> NSManagedObjectModel {
        let url = NSBundle.mainBundle().URLForResource(storeName, withExtension: "momd")
        let managedObjectModel = NSManagedObjectModel(contentsOfURL: url!)
        return managedObjectModel!
    }
    
    private func createPersistentStoreCoordinater(storeName: String) -> NSPersistentStoreCoordinator {
        let storeUrl = self.applicationDocumentDirectory().URLByAppendingPathComponent("\(storeName).sqlite")
        var error:NSError?
        
        let persistentStoreCoordinater = NSPersistentStoreCoordinator(managedObjectModel: createManagedObjectModel(storeName))
        let checkPersistent = persistentStoreCoordinater.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeUrl, options: nil, error: &error)
        
        switch checkPersistent {
        case .Some(let persistent):
            return persistentStoreCoordinater
        case .None:
            println("Unresolved error \(error!) \(error!.userInfo)")
            abort()
        }
    }
    
    func createFetchedResultsController(request: NSFetchRequest) -> NSFetchedResultsController {
        let resultController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.childContext, sectionNameKeyPath: nil, cacheName: nil)
        var error: NSError?
        resultController.performFetch(&error)
        return resultController
    }
    
    func createFetchRequest(entityName: String, sortKey: String?, limit: Int) -> NSFetchRequest {
        let request = NSFetchRequest()
        let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: self.childContext)
        
        request.entity = entity
        request.fetchLimit = limit
        
        request.sortDescriptors = sortKey.map { [NSSortDescriptor(key: $0, ascending: false)] }
        
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
