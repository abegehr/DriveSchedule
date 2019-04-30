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
import HMKit
import AutoAPI


class FirstViewController: UIViewController {

    @IBOutlet weak var Map: MKMapView!
    var vehicleSerialData: [UInt8] = []
    var vehicleAnnotation = MKPointAnnotation()
    var vehilceLocationTimer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // HM: check vehicle certificate is registered
        if (HMKit.shared.registeredCertificates.count >= 0) {
            vehicleSerialData = HMKit.shared.registeredCertificates[0].gainingSerial
        }
        
        // add vehicle location to map
        do {
            try HMTelematics.sendCommand(AAVehicleLocation.getLocation.bytes , serial: vehicleSerialData) { response in
                if case HMTelematicsRequestResult.success(let data) = response {
                    guard let data = data else {
                        return print("Missing response data")
                    }
                    
                    // parse
                    guard let vehicleLocation = AutoAPI.parseBinary(data) as? AAVehicleLocation else {
                        return print("Failed to parse Auto API")
                    }
                    
                    // get coordinates
                    guard let vehicleLocationCoord = vehicleLocation.coordinates?.value else {
                        return print("Failed to get vehicle location coordinates.")
                    }
                    
                    // successfully got vehicle location
                    let location = CLLocationCoordinate2DMake(vehicleLocationCoord.latitude, vehicleLocationCoord.longitude)
                    
                    // center map on vehicle
                    let span = MKCoordinateSpan.init(latitudeDelta: 0.06, longitudeDelta: 0.06)
                    let region = MKCoordinateRegion(center: location, span: span)
                    self.Map.setRegion(region, animated: true)
                    
                    // add point annotation
                    self.vehicleAnnotation = MKPointAnnotation()
                    self.vehicleAnnotation.coordinate = location
                    self.vehicleAnnotation.title = "Vehicle"
                    self.vehicleAnnotation.subtitle = "This is where your vehicle is currently!"
                    self.Map.addAnnotation(self.vehicleAnnotation)
                }
                else {
                    print("Failed to get vehicle location: \(response).")
                }
            }
        }
        catch {
            print("Failed to send command:", error)
        }
        
        
        // check for the current vehicle location once a second
        scheduleVehicleLocationUpdates()
        
    }
    
    func scheduleVehicleLocationUpdates() {
        vehilceLocationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {_ in
            // get current vehicle location
            do {
                try HMTelematics.sendCommand(AAVehicleLocation.getLocation.bytes , serial: self.vehicleSerialData) { response in
                    if case HMTelematicsRequestResult.success(let data) = response {
                        guard let data = data else {
                            return print("Missing response data")
                        }
                        
                        // parse
                        guard let vehicleLocation = AutoAPI.parseBinary(data) as? AAVehicleLocation else {
                            return print("Failed to parse Auto API")
                        }
                        
                        // get coordinates
                        guard let vehicleLocationCoord = vehicleLocation.coordinates?.value else {
                            return print("Failed to get vehicle location coordinates.")
                        }
                        
                        // successfully got vehicle location
                        let location = CLLocationCoordinate2DMake(vehicleLocationCoord.latitude, vehicleLocationCoord.longitude)
                        
                        // update vehicle location on map
                        self.vehicleAnnotation.coordinate = location
                    }
                    else {
                        print("Failed to get vehicle location: \(response).")
                    }
                }
            }
            catch {
                print("Failed to send command:", error)
            }
        })
    }


}

