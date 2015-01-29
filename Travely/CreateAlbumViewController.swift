//
//  CreateAlbumViewController.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/30.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import UIKit

class CreateAlbumViewController: UIViewController {

    @IBOutlet weak var not_show_image: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.not_show_image.image = UIImage(named: "not_show.jpg")
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func blurEffectView(fromBlurStyle style: UIBlurEffectStyle, frame: CGRect) -> UIVisualEffectView {
        let effect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: effect)
        blurView.frame = frame
        return blurView
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
