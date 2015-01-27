//
//  CreateTravelViewController.swift
//  Travely
//
//  Created by yuichiro_t on 2014/11/19.
//  Copyright (c) 2014年 Yuichiro Takahashi. All rights reserved.
//

import UIKit

class CreateTravelViewController: UIViewController, RATreeViewDelegate, RATreeViewDataSource {
    
    @IBOutlet weak var destinationPlaceLabel: UILabel!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    private var treeView: RATreeView!
    
    private let defaultMapDataManager: TRDefaultMapDataManager!
    private let kPlaceDatas: [TRTreeViewDataModel]!
    private let kPlaceCell = "placeCell"
    private var selectedPlaceName: String?
    private let kDefaultText = "どこにお出かけですか？"
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.defaultMapDataManager = TRDefaultMapDataManager.sharedManager
        self.kPlaceDatas = self.regions2TRTreeViewDataModel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.treeView = self.initializeTreeView()
        self.destinationPlaceLabel.text = kDefaultText
        self.barButtonHiddenOrShow()
        self.view.addSubview(self.treeView)
    }
    
    private func regions2TRTreeViewDataModel() -> [TRTreeViewDataModel] {
        return self.defaultMapDataManager.getRegionsName().map { name -> TRTreeViewDataModel in
            TRTreeViewDataModel(name: name, children: self.prefectures2TRTreeViewDataModel(name))
        }
    }
    
    private func prefectures2TRTreeViewDataModel(regionName: String) -> [TRTreeViewDataModel] {
        return self.defaultMapDataManager.getPrefecturesNameWithRegionName(regionName).map {
            prefName -> TRTreeViewDataModel in
            TRTreeViewDataModel(name: prefName, children: [TRTreeViewDataModel(name: "nil", children: nil)])
        }
    }
    
    private func initializeTreeView() -> RATreeView {
        let treeView = RATreeView(frame: CGRectMake(0, 333, 375, 334))
        treeView.delegate = self
        treeView.dataSource = self
        treeView.bounces = false
        return treeView
    }
    
    private func setCellAttributesWithLevel(cell: UITableViewCell, level: Int, andModel model: TRTreeViewDataModel) -> UITableViewCell {
        switch level {
        case 0: cell.backgroundColor = TRDrawUtils.getActivityColorWithHex(0x90EE90)
        case 1:
            cell.backgroundColor = TRDrawUtils.getActivityColorWithHex(0x87CEEB)
            cell.accessoryView? = createButton()
        default: cell.backgroundColor = TRDrawUtils.getActivityColorWithHex(0x90EE90)
        }
        cell.textLabel?.text = model.name
        cell.selectionStyle = .None
        return cell
    }
    
    private func createButton() -> UIButton {
        TRLog.log("createButton!")
        let button = UIButton()
        button.setTitle("+", forState: .Normal)
        button.frame = CGRectMake(0, 0, 20, 20)
        button.tag = 1
        button.layer.cornerRadius = 10
        button.addTarget(self, action: "tapped:", forControlEvents:.TouchUpInside)
        return button
    }
    
    func tapped(sender: AnyObject) {
        TRLog.log("tapped!")
    }
    
    private func barButtonHiddenOrShow() {
        if self.destinationPlaceLabel.text == kDefaultText {
            self.nextButton.enabled = false
            self.nextButton.tintColor = UIColor(white: 0, alpha: 0)
            return
        }
        
        self.nextButton.enabled = true
        self.nextButton.tintColor = nil
    }
    
    //MARK: - tree view delegate
    func treeView(treeView: RATreeView!, willSelectRowForItem item: AnyObject!) -> AnyObject! {
        let cell = self.treeView(treeView, cellForItem: item) as UITableViewCell
        let obj = item as TRTreeViewDataModel
        let level = self.treeView.levelForCellForItem(item)
        
        if level == 1 {
            self.destinationPlaceLabel.text = obj.name
            self.barButtonHiddenOrShow()
            return nil
        }
        return cell
    }
    
    
    //MARK: - tree view data source
    func treeView(treeView: RATreeView!, numberOfChildrenOfItem item: AnyObject!) -> Int {
        switch item {
        case .Some(let model) where (model as TRTreeViewDataModel).children != nil:
            return (model as TRTreeViewDataModel).children!.count
        default:
            return self.kPlaceDatas.count
        }
    }
    
    func treeView(treeView: RATreeView!, cellForItem item: AnyObject!) -> UITableViewCell! {
        let model = item as TRTreeViewDataModel
        let level = self.treeView.levelForCellForItem(item)
        let numberOfChildren = model.children!.count
        let cell: UITableViewCell? = self.treeView.dequeueReusableCellWithIdentifier(kPlaceCell) as? UITableViewCell
        
        switch cell {
        case .Some(let c): return setCellAttributesWithLevel(c, level: level, andModel: model)
        case .None:
            let c = UITableViewCell(style: .Default, reuseIdentifier: kPlaceCell)
            return setCellAttributesWithLevel(c, level: level, andModel: model)
        }
    }
    
    func treeView(treeView: RATreeView!, child index: Int, ofItem item: AnyObject!) -> AnyObject! {
        switch item as? TRTreeViewDataModel {
        case .Some(let model) where model.children != nil: return model.children![index]
        default: return self.kPlaceDatas[index]
        }
    }
}
