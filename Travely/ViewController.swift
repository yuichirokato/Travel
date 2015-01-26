//
//  ViewController.swift
//  Travely
//
//  Created by yuichiro_t on 2014/11/14.
//  Copyright (c) 2014年 Yuichiro Takahashi. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {
    
    var router: TRRouter?
    let manager = TRDefaultMapDataManager.sharedManager
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.router = TRRouter()
            
        if (!isLaunchedAfterFirst()) {
            println("firstest!")
            setDefaultData()
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasLaunchedOnce")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        manager.getRegionsName().foreach { TRLog.log("getRegionName = \($0)") }
    }
    
    func isLaunchedAfterFirst() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("HasLaunchedOnce")
    }
    
    func setDefaultData() {
        let path = NSBundle.mainBundle().pathForResource("areaName01", ofType: ".json")
        let fileHandle = NSFileHandle(forReadingAtPath: path!)
        let data = fileHandle?.readDataToEndOfFile()
        let json = JSON(data: data!)
        manager.insertMapData(json["Results"]["Area"])
        
        let array = (Array<Int>)(5...55)
        array.filter { $0 % 5 == 0 }.foreach { index in
            let fileName = String(format: "areaName%02d", index)
            let path = NSBundle.mainBundle().pathForResource(fileName, ofType: ".json")
            let fileHandle = NSFileHandle(forReadingAtPath: path!)
            let data = fileHandle?.readDataToEndOfFile()
            let json = JSON(data: data!)
            self.manager.insertMapData(json["Results"]["Area"])
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func showLocalMap(sender: AnyObject) {
        self.navigationController.foreach { nc in
            if let sb = self.storyboard {
                let displaySaveTravelViewController = sb.instantiateViewControllerWithIdentifier("DisplaySaveTravelViewController") as UIViewController
                nc.pushViewController(displaySaveTravelViewController, animated: true)
            }
        }
    }
}

