//
//  CreateTravelViewController.swift
//  Travely
//
//  Created by yuichiro_t on 2014/11/19.
//  Copyright (c) 2014年 Yuichiro Takahashi. All rights reserved.
//

import UIKit
import ReactiveCocoa

class CreateTravelViewController: UIViewController {
    
    @IBOutlet weak var destinationPlaceLabel: UILabel!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    private var treeView: RATreeView!
    
    private let defaultMapDataManager: TRDefaultMapDataManager!
    private let travelDatamanager: TRTravelDataManager!
    private let kPlaceDatas: [TRTreeViewDataModel]!
    private let kViewStateSelectRegionView: Int = 0
    private let kViewStateSelectDetailView: Int = 1
    private let kviewStateSelectTermView: Int = 2
    
    struct Static {
        static var isSaveTravel = false
    }
    
    class var isSaveTravel: Bool {
        get { return Static.isSaveTravel }
        set { Static.isSaveTravel = newValue }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.defaultMapDataManager = TRDefaultMapDataManager.sharedManager
        self.travelDatamanager = TRTravelDataManager.sharedManager
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let selectRegionView = SelectRegionView(frame: self.view.bounds)
        self.navigationItem.title = "目的地選択（県）"
        self.changeViewWithFromView(selectRegionView, viewState: kViewStateSelectRegionView)
        
        self.view.addSubview(selectRegionView)
    }
    
    private func changeViewWithFromView(fromView: UIView, viewState: Int) {
        switch viewState {
        case 0:
            setSignalsForselectDetailAreaView(fromView, viewState: viewState)
        case 1:
            setSignalsForSelectTermView(fromView, viewState: viewState)
        default:
            setSignalsForselectDetailAreaView(fromView, viewState: viewState)
        }
    }
    
    private func setSignalsForselectDetailAreaView(selectRegionView: UIView, viewState: Int) {
        let command = RACCommand(enabled: self.setEnableForNextButton(selectRegionView,
        key: "kPrefLabel.text")) { input -> RACSignal! in
            self.navigationItem.title = "目的地選択（詳細地域）"
            let regionView = selectRegionView as SelectRegionView
            let selectDetailAreaView = SelectDetailAreaView(frame: self.view.bounds,
                selectedPref: regionView.kPrefLabel.text!)
            self.view.addSubview(selectDetailAreaView)
            selectDetailAreaView.alpha = 0.0
            self.animationFadeInAndFadeOut(selectRegionView, fadeInView: selectDetailAreaView)
            self.changeViewWithFromView(selectDetailAreaView, viewState: self.kViewStateSelectDetailView)
            return RACSignal.empty()
        }
        self.nextButton.rac_command = command
    }
    
    private func setSignalsForSelectTermView(view: UIView, viewState: Int) {
        let command = RACCommand(enabled: self.setEnableForNextButton(view, key: "kDetailAreaLabel.text")) {
            input -> RACSignal! in
            self.navigationItem.title = "旅行期間選択"
            let selectDetailAreaView = view as SelectDetailAreaView
            self.nextButton.tintColor = UIColor(white: 0, alpha: 0)
            self.nextButton.enabled = false
            
            let nib = UINib(nibName: "CreateTravelView", bundle: nil)
            let selectTermview = nib.instantiateWithOwner(nil, options: nil)[0] as SelectTermView
            selectTermview.prefectureLabel.text = selectDetailAreaView.kSelectedPrefLabel.text
            selectTermview.detailAreaLAbel.text = selectDetailAreaView.kDetailAreaLabel.text
            
            let completeSignal = selectTermview.completeCreateTravelBtn.rac_command.executionSignals.flatten()
            
            self.rac_liftSelector("startSaveTravel:", withSignalsFromArray: [completeSignal])
            
            self.view.addSubview(selectTermview)
            
            selectTermview.alpha = 0.0
            self.animationFadeInAndFadeOut(selectDetailAreaView, fadeInView: selectTermview)
            
            return RACSignal.empty()
        }
        self.nextButton.rac_command = command
    }
    
    private func setEnableForNextButton(stateView: UIView, key: String) -> RACSignal {
        return stateView.rac_valuesForKeyPath(key, observer: stateView).map {
            text -> AnyObject! in (text as String) != ""
        }
    }
    
    private func animationFadeInAndFadeOut(fadeOutView: UIView, fadeInView: UIView) {
        UIView.animateWithDuration(1.0, animations: { fadeOutView.alpha = 0.0 }, completion: { value in
            UIView.animateWithDuration(1.0) { fadeInView.alpha = 1.0 }
        })
    }
    
    func startSaveTravel(sender: AnyObject) {
        
        self.view.subviews.foreach { view in (view as UIView).removeFromSuperview() }
        
        let localMapViewController = self.storyboard!.instantiateViewControllerWithIdentifier("localMapViewController") as LocalMapViewController
        self.sidePanelController.centerPanel = UINavigationController(rootViewController: localMapViewController)
    }
}
