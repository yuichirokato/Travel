//
//  ViewController.swift
//  Travely
//
//  Created by yuichiro_t on 2014/11/14.
//  Copyright (c) 2014年 Yuichiro Takahashi. All rights reserved.
//

import UIKit
import Foundation
import ReactiveCocoa

class ViewController: UIViewController {
    
    var router: TRRouter?
    let manager = TRDefaultMapDataManager.sharedManager
    let imageData = ["IMG_4091.JPG", "IMG_4093.JPG", "IMG_4094.JPG", "IMG_4095.JPG", "IMG_4097.JPG"
    , "IMG_4098.JPG", "IMG_4099.jpg", "IMG_4101.JPG", "IMG_4102.JPG", "IMG_4103.JPG"]
    
    @IBOutlet weak var travelImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.router = TRRouter()
        
        self.travelImage.alpha = 0.0
        self.travelImage.image = UIImage(named: self.imageData[8])
        
        if (!isLaunchedAfterFirst()) {
            println("firstest!")
            setDefaultData()
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasLaunchedOnce")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        self.animationImage()
        
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
    
    private func animationImage() {
        let randomNumber = arc4random() % UInt32(self.imageData.count)
        let image = UIImage(named: self.imageData[Int(randomNumber)])
        
        UIView.animateWithDuration(4.0, animations: { self.travelImage.alpha = 0.0 }, completion: { value in
            UIView.animateWithDuration(4.0) {
                self.travelImage.image = image
                self.travelImage.alpha = 1.0
                self.animationImage()
            }
        })
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

