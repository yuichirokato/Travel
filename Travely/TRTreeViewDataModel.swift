//
//  TRTreeViewDataModel.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/27.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import UIKit

class TRTreeViewDataModel: NSObject {
   
    let name: String!
    let children: [TRTreeViewDataModel]?
    
    init(name: String, children:[TRTreeViewDataModel]?) {
        super.init()
        self.name = name
        self.children = children
    }
}
