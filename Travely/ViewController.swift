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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.router = TRRouter()
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

