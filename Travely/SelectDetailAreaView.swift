//
//  SelectDetailAreaView.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/28.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import UIKit

class SelectDetailAreaView: UIView, RATreeViewDataSource, RATreeViewDelegate {
    
    private var treeView: RATreeView!
    var kLargeAreaLabel: UILabel!
    var kSelectedPrefLabel: UILabel!
    var kDetailAreaLabel: UILabel!
    var kDestinationLabel: UILabel!
    private var selectedPrefecture: String!
    private var defaultMapDataManager: TRDefaultMapDataManager!
    private var kPlaceDatas: [TRTreeViewDataModel]!
    private let kPlaceCell = "placeCell"
    private let kDefaultText = "どの地域にお出かけですか？"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeView()
    }
    
    convenience init(frame: CGRect, selectedPref: String) {
        self.init(frame: frame)
        self.selectedPrefecture = selectedPref
        self.initializeLabel()
        self.kPlaceDatas = TRCreateTravelModel.largeAreas2TRTreeViewDataModel(selectedPref)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeView()
    }
    
    private func initializeView() {
        self.defaultMapDataManager = TRDefaultMapDataManager.sharedManager
        self.treeView = initializeTreeView()
        self.addSubview(self.treeView)
    }
    
    private func initializeLabel() {
        self.kLargeAreaLabel = UILabel(frame: CGRect(x: 72, y: 142, width: 230, height: 25))
        self.kLargeAreaLabel.text = kDefaultText
        self.kLargeAreaLabel.textAlignment = .Center
        
        self.kDestinationLabel = UILabel(frame: CGRect(x: 72, y: 82, width: 100, height: 25))
        self.kDestinationLabel.text = "旅行先(県):　"
        self.kDestinationLabel.textAlignment = .Center
        
        self.kSelectedPrefLabel = UILabel(frame: CGRect(x: 102, y: 82, width: 230, height: 25))
        self.kSelectedPrefLabel.text = selectedPrefecture
        self.kSelectedPrefLabel.textAlignment = .Center
        
        self.kDetailAreaLabel = UILabel(frame: CGRect(x: 72, y: 182, width: 230, height: 25))
        self.kDetailAreaLabel.text = ""
        self.kDetailAreaLabel.textAlignment = .Center
        
        self.addSubview(self.kLargeAreaLabel)
        self.addSubview(self.kDestinationLabel)
        self.addSubview(self.kSelectedPrefLabel)
        self.addSubview(self.kDetailAreaLabel)
        
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
            self.kDetailAreaLabel.text = obj.name
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


