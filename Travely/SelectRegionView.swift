//
//  SelectRegionView.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/27.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import UIKit

class SelectRegionView: UIView, RATreeViewDataSource, RATreeViewDelegate {
    
    private var treeView: RATreeView!
    var kRegionLabel: UILabel!
    var kPrefLabel: UILabel!
    
    private var defaultMapDataManager: TRDefaultMapDataManager!
    private var kPlaceDatas: [TRTreeViewDataModel]!
    private let kPlaceCell = "placeCell"
    private let kDefaultText = "どの県にお出かけですか？"
    private var selectedPlaceName: String = "どの県にお出かけですか？"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = frame
        self.initializeView()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeView()
    }
    
    private func initializeView()  {
        self.defaultMapDataManager = TRDefaultMapDataManager.sharedManager
        self.treeView = initializeTreeView()
        self.kPlaceDatas = TRCreateTravelModel.regions2TRTreeViewDataModel()
        self.initializeLabel()
        self.addSubview(self.treeView)
    }
    
    private func initializeLabel() {
        self.kRegionLabel = UILabel(frame: CGRect(x: 72, y: 102, width: 230, height: 25))
        self.kRegionLabel.text = kDefaultText
        self.kRegionLabel.textAlignment = .Center
        
        self.kPrefLabel = UILabel(frame: CGRect(x: 72, y: 122, width: 230, height: 25))
        self.kPrefLabel.text = ""
        self.kPrefLabel.textAlignment = .Center
        
        self.addSubview(self.kRegionLabel)
        self.addSubview(self.kPrefLabel)
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
        case 0:  cell.backgroundColor = TRDrawUtils.getActivityColorWithHex(0x90EE90)
        case 1:  cell.backgroundColor = TRDrawUtils.getActivityColorWithHex(0x87CEEB)
        default: cell.backgroundColor = TRDrawUtils.getActivityColorWithHex(0x90EE90)
        }
        cell.textLabel?.text = model.name
        cell.selectionStyle = .None
        return cell
    }
    
    //MARK: - tree view delegate
    func treeView(treeView: RATreeView!, willSelectRowForItem item: AnyObject!) -> AnyObject! {
        let cell = self.treeView(treeView, cellForItem: item) as UITableViewCell
        let obj = item as TRTreeViewDataModel
        let level = self.treeView.levelForCellForItem(item)
        
        if level == 1 {
            self.kPrefLabel.text = obj.name
            self.selectedPlaceName = obj.name
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
