//
//  SelectTermView.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/29.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import UIKit
import ReactiveCocoa

class SelectTermView: UIView {
    
    @IBOutlet weak var departureDateLabel: UILabel!
    @IBOutlet weak var returnDateLabel: UILabel!
    @IBOutlet weak var prefectureLabel: UILabel!
    @IBOutlet weak var detailAreaLAbel: UILabel!
    
    @IBOutlet weak var completeCreateTravelBtn: UIButton!
    @IBOutlet weak var departureDateBtn: UIButton!
    @IBOutlet weak var returnDateBtn: UIButton!
    
    
    private let LABEL_DEPARTURE: Int = 0
    private let LABEL_RETURN: Int = 1
    private let FIRST_YEAR: Int = NSDate().toString("yyyy").toIntAsUnwrapOpt() - 1
    private let LAST_YEAR: Int = NSDate().toString("yyyy").toIntAsUnwrapOpt() + 2
    private let kTravelTermDateFormat = "yyyy／MM／dd"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        
        self.initializeView()
    }
    
    private func initializeView() {
        
        let today = NSDate().toString(self.kTravelTermDateFormat)
        
        self.departureDateLabel.text = today
        self.departureDateBtn.rac_command = self.createCallDatePickerCommandWithDepartureOrReturn(LABEL_DEPARTURE)
        
        self.returnDateLabel.text = today
        self.returnDateBtn.rac_command = self.createCallDatePickerCommandWithDepartureOrReturn(LABEL_RETURN)
        
        self.completeCreateTravelBtn.backgroundColor = TRDrawUtils.getActivityColorWithHex(0x00FA9A)
        self.completeCreateTravelBtn.rac_command = RACCommand(enabled: self.createEnabledSignal(today)) {
            input -> RACSignal in RACSignal.`return`(input)
        }
    }
    
    private func createCallDatePickerCommandWithDepartureOrReturn(departureOrReturn: Int) -> RACCommand {
        return RACCommand() { input -> RACSignal in
            self.showDateSelectionViewController(departureOrReturn)
            TRLog.log("message!")
            return RACSignal.empty()
        }
    }
    
    private func createEnabledSignal(today: String) -> RACSignal {
        return self.rac_valuesForKeyPath("returnDateLabel.text", observer: self).map {
            text -> AnyObject! in (text as String) != today
        }
    }
    
    private func showDateSelectionViewController(departureOrReturn: Int) {
        let dateSelectionViewController = RMDateSelectionViewController.dateSelectionController()
        dateSelectionViewController.hideNowButton = true
        dateSelectionViewController.datePicker.datePickerMode = .Date
        dateSelectionViewController.showWithSelectionHandler( { vc, date in
            switch departureOrReturn {
            case self.LABEL_DEPARTURE: self.departureDateLabel.text = date.toString(self.kTravelTermDateFormat)
            case self.LABEL_RETURN : self.returnDateLabel.text = date.toString(self.kTravelTermDateFormat)
            default: break
            }
        }, andCancelHandler: nil)
    }
}
