//
//  LocalMapViewController.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/16.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreMotion

class ColorPolyline: MKPolyline {
    var drawColor: UIColor = UIColor.grayColor()
}

class LocalMapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var localMapView: MKMapView!
    private var locationManager = CLLocationManager()
    private var locationItems: [UserLocateMotion] = [UserLocateMotion]()
    private var activityManager: CMMotionActivityManager?
    private var motionActivity: CMMotionActivity?
    private var defrredLocationUpdates = false
    private var lastAnnotation = ""
    private let travelDataManager = TRTravelDataManager.sharedManager
    
    private let kLocationDistance: CLLocationDistance = 100.0
    private let kTimeInterval: NSTimeInterval = 30.0
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        travelDataManager.deleteAllUserPath()
        
        let status = CLLocationManager.authorizationStatus()
        
        if status == .NotDetermined {
            self.locationManager.requestAlwaysAuthorization()
        }
        
        self.locationManager.delegate = self
        self.locationManager.activityType = .OtherNavigation
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.startUpdatingLocation()
        
        if CMMotionActivityManager.isActivityAvailable() {
            self.startGettingMotionActivity()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if CMMotionActivityManager.isActivityAvailable() {
            stopGettingMotionActivity()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let locate = locations as [CLLocation]
        locate.foreach { lc in
            let userLocateMotion = UserLocateMotion(location: lc, activity: self.motionActivity)
            let colorHex = TRUtils.getColorHexWithActivity(userLocateMotion.activity)
            self.travelDataManager.insertUserPath(userLocateMotion, activityColorHex: colorHex)
            if self.locationItems.count > 1 {
                if !self.locationItems.last!.isSameActivity(userLocateMotion) {
                    self.drawActivity()
                }
            }
            self.locationItems.append(userLocateMotion)
        }
        
        if !self.defrredLocationUpdates {
            self.locationManager.allowDeferredLocationUpdatesUntilTraveled(kLocationDistance, timeout: kTimeInterval)
            self.defrredLocationUpdates = true
        }
        
    }
    
    // MARK: - map job
    func drawActivity() {
        if self.locationItems.count <= 1 {
            return
        }
        
        var coordinaters = self.locationItems.map {
            (let item: UserLocateMotion) -> CLLocationCoordinate2D in
            
            let coordinate = item.location.coordinate
            let annotationString = item.location.timestamp.toString("HH:mm")
            let minute = annotationString.toNSString().substringFromIndex(3).toIntAsUnwrapOpt()
            
            if minute % 5 == 0 {
                if annotationString != self.lastAnnotation {
                    let point = MKPointAnnotation()
                    point.coordinate = coordinate
                    point.title = annotationString
                    self.localMapView.addAnnotation(point)
                    self.localMapView.selectAnnotation(point, animated: true)
                    self.lastAnnotation = annotationString
                }
            }
            return coordinate
        }
        
        let polyline = ColorPolyline(coordinates: &coordinaters, count: self.locationItems.count)
        let lastItem = self.locationItems.last! as UserLocateMotion
        polyline.drawColor = TRDrawUtils.getActivityColor(lastItem.activity)
        self.localMapView.addOverlay(polyline, level: .AboveRoads)
        
        let lastItemIndex = self.locationItems.count - 1
        self.locationItems.removeRange(0..<lastItemIndex)
    }
    
    // MARK: - coremotion job
    func startGettingMotionActivity() {
        self.activityManager = CMMotionActivityManager()
        self.activityManager!.startActivityUpdatesToQueue(NSOperationQueue.mainQueue()) { activity in
            dispatch_async(dispatch_get_main_queue()) {
                self.motionActivity = activity
            }
        }
    }
    
    func stopGettingMotionActivity() {
        self.activityManager!.stopActivityUpdates()
        self.activityManager = .None
    }

}
