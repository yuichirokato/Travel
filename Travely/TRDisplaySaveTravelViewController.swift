//
//  TRDisplaySaveTravelViewController.swift
//  Travely
//
//  Created by yuichiro_t on 2015/01/16.
//  Copyright (c) 2015年 Yuichiro Takahashi. All rights reserved.
//

import UIKit
import MapKit

class TRDisplaySaveTravelViewController: UIViewController, MKMapViewDelegate {
    
    private let kLineWidth: CGFloat = 10.0
    private let kAlphaComponent: CGFloat = 0.7
    var paths: [UserPath]?

    @IBOutlet weak var displaySaveTravelMapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switch paths {
        case .Some(let locations) where locations.count > 0: drawActivity(locations)
        default: NSLog("None userPaths Data!")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func drawActivity(paths: [UserPath]) {
        var coordinates = paths.map { (path: UserPath) -> CLLocationCoordinate2D in
            let lat = CLLocationDegrees(path.latitude!)
            let long = CLLocationDegrees(path.longitude!)
            return CLLocationCoordinate2D(latitude: lat, longitude: long)
        }
        
        let polyLine = ColorPolyline(coordinates: &coordinates, count: coordinates.count)
        let lastItem = paths.last!
        polyLine.drawColor = TRDrawUtils.getActivityColorWithHex(TRUtils.getColorHexWithUserPath(lastItem))
        self.displaySaveTravelMapView.addOverlay(polyLine, level: .AboveRoads)
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        let polyLine = overlay as ColorPolyline
        let rendrer = MKPolylineRenderer(polyline: polyLine)
        rendrer.strokeColor = polyLine.drawColor.colorWithAlphaComponent(kAlphaComponent)
        rendrer.lineWidth = kLineWidth
        
        return rendrer
    }
}
