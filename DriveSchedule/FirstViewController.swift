//
//  FirstViewController.swift
//  DriveSchedule
//
//  Created by Anton Begehr on 07.04.19.
//  Copyright © 2019 Anton Begehr. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


class FirstViewController: UIViewController {

    @IBOutlet weak var Map: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // location of Berlin
        let location = CLLocationCoordinate2DMake(52.523430, 13.411440)
        
        // center map on Berlin
        let span = MKCoordinateSpan.init(latitudeDelta: 0.06, longitudeDelta: 0.06)
        let region = MKCoordinateRegion(center: location, span: span)
        Map.setRegion(region, animated: true)
        
        // add point annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = "Annotation"
        annotation.subtitle = "This is the place!"
        
        Map.addAnnotation(annotation)
    }


}

