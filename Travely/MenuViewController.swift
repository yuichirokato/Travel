//
//  MenuViewController.swift
//  Travely
//
//  Created by yuichiro_t on 2014/11/19.
//  Copyright (c) 2014年 Yuichiro Takahashi. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let nameArray = ["思い出を振り返る", "思い出を作る", "アルバムを作る", "ShareMapを見る"]
    
    @IBOutlet var tableview: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeTableView()
    }
    
    private func initializeTableView() {
        let insets = self.tableview.contentInset
        let result = insets.top + CGFloat(20.0)
        self.tableview.contentInset = UIEdgeInsetsMake(result, insets.left, insets.bottom, insets.right)
        self.tableview.delegate = self
        self.tableview.dataSource = self
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableview.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell
        cell.textLabel!.text = nameArray[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        
        cell.foreach { c in
            switch c.textLabel!.text {
            case .Some(let text) where text == "思い出を振り返る":
                let viewController = TRUtils.getViewController("mainView")
                self.sidePanelController.centerPanel = UINavigationController(rootViewController: viewController)
            
            case .Some(let text) where text == "思い出を作る":
                let viewController = TRUtils.getViewController("createTravelView")
                self.sidePanelController.centerPanel = UINavigationController(rootViewController: viewController)
                
            case .Some(let text) where text == "アルバムを作る":
                let viewController = TRUtils.getViewController("")
                self.sidePanelController.centerPanel = UINavigationController(rootViewController: viewController)
                
            case .Some(let text) where text == "ShareMapを見る":
                let viewController = TRUtils.getViewController("")
                self.sidePanelController.centerPanel = UINavigationController(rootViewController: viewController)
                
            default:
                println("うまく遷移できませんでした！")
            }
        }
    }
}

