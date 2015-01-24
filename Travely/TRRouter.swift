//
//  TRRouter.swift
//  Travely
//
//  Created by yuichiro_t on 2014/11/18.
//  Copyright (c) 2014年 Yuichiro Takahashi. All rights reserved.
//

import UIKit

class TRRouter: NSObject {
    var targetController: UIViewController?
    
    class var sharedRouter: TRRouter {
        struct Static {
            static let router = TRRouter()
        }
        return Static.router
    }
    
    func setTargetController(controller: UIViewController?) {
        self.targetController = controller
    }
    
    func pushViewController(toViewContoller: UIViewController, animated: Bool) {
        switch self.targetController {
        case .Some(let navigation as UINavigationController):
            navigation.pushViewController(toViewContoller, animated: animated)
        default:
            println("画面のpushに失敗しました")
        }
    }
}
