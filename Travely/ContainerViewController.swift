//
//  ContainerViewController.swift
//  Travely
//
//  Created by yuichiro_t on 2014/11/18.
//  Copyright (c) 2014年 Yuichiro Takahashi. All rights reserved.
//

import UIKit

class ContainerViewController: JASidePanelController {
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initializeContainerView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func initializeContainerView() {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let leftController = storyBoard.instantiateViewControllerWithIdentifier("menuView") as MenuViewController
        let centerController = storyBoard.instantiateViewControllerWithIdentifier("mainView") as ViewController
        
        self.leftPanel = leftController
        self.centerPanel = UINavigationController(rootViewController: centerController)
    }
}
