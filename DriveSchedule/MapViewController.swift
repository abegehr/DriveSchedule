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
import EventKit


class MapViewController: UIViewController {

    @IBOutlet weak var Map: MKMapView!
    // HM
    var vehicleSerialData: [UInt8] = []
    var vehicleAnnotation = MKPointAnnotation()
    var vehilceLocationTimer = Timer()
    // EK
    var eventStore = EKEventStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // HM: check vehicle certificate is registered
        if (HMKit.shared.registeredCertificates.count >= 0) {
            vehicleSerialData = HMKit.shared.registeredCertificates[0].gainingSerial
        }
        
        // vehicle location
        showVehicleLocation()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // calendar events
        showCalendarEvents()
    }
    
    func showVehicleLocation() {
        if (self.vehicleSerialData == []) {
            return print("ERROR Not connected to a vehicle.")
        }
        
        // add vehicle location to map
        do {
            try HMTelematics.sendCommand(AAVehicleLocation.getLocation.bytes , serial: vehicleSerialData) { response in
                if case HMTelematicsRequestResult.success(let data) = response {
                    guard let data = data else {
                        return print("ERROR Missing response data")
                    }
                    
                    // parse
                    guard let vehicleLocation = AutoAPI.parseBinary(data) as? AAVehicleLocation else {
                        return print("ERROR Failed to parse Auto API")
                    }
                    
                    // get coordinates
                    guard let vehicleLocationCoord = vehicleLocation.coordinates?.value else {
                        return print("ERROR Failed to get vehicle location coordinates.")
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
                    print("ERROR Failed to get vehicle location: \(response).")
                }
            }
        }
        catch {
            print("ERROR Failed to send command:", error)
        }
        
        
        // check for the current vehicle location once a second
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

    func showCalendarEvents() {
        eventStore.requestAccess(to: EKEntityType.event, completion: {
            (accessGranted: Bool, error: Error?) in
            
            if accessGranted {
                // access to calendar granted
                
                // get today's events from normal calendars
                // get today's start and end of day
                let cal = Calendar.current
                let date = Date()
                let date0 = cal.startOfDay(for: date)
                let date24 = cal.date(byAdding: DateComponents(day: 1, second: -1), to: date0)!
                // get normal calendars
                var calendars = self.eventStore.calendars(for: EKEntityType.event)
                calendars = calendars.filter { $0.type == EKCalendarType.calDAV || $0.type == EKCalendarType.local || $0.type == EKCalendarType.subscription || $0.type == EKCalendarType.exchange }
                print("Getting calendar events between \(date0) and \(date24) of calendars: \(calendars).")
                var events = self.eventStore.events(matching: self.eventStore.predicateForEvents(withStart: date0, end: date24, calendars: calendars))
                
                // remove all-day events
                events = events.filter { $0.isAllDay == false }
                
                //print("Loaded events: ", events)
                
                // show events on map
                for event in events {
                    self.showEventOnMap(event: event)
                }
            } else {
                print("ERROR No access to user's calendar.")
            }
        })
    }
    
    func showEventOnMap(event: EKEvent) {
        guard let location = event.location else {
            return print("ERROR Could not get event location for event: ", event)
        }
        if location == "" {
            return //print("Empty event location.")
        }
        print("Showing event at: ", location)
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { placemarks, error in
            if let placemark = placemarks?.first, let location = placemark.location {
                let mark = MKPointAnnotation()
                mark.coordinate = location.coordinate
                mark.title = event.title
                mark.subtitle = event.location
                self.Map.addAnnotation(mark)
            }
        }
    }
    
}

