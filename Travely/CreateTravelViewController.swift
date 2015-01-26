//
//  CreateTravelViewController.swift
//  Travely
//
//  Created by yuichiro_t on 2014/11/19.
//  Copyright (c) 2014年 Yuichiro Takahashi. All rights reserved.
//

import UIKit

class CreateTravelViewController: UIViewController {
    
    @IBOutlet weak var selectDestinationTableView: UITableView!
    
    private let defaultMapDataManager: TRDefaultMapDataManager!
    private let regionsArray: [String]!
    
    override init() {
        super.init()
        self.defaultMapDataManager = TRDefaultMapDataManager.sharedManager
        self.regionsArray = self.defaultMapDataManager.getRegionsName()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
}
