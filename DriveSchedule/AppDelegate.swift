//
//  AppDelegate.swift
//  DriveSchedule
//
//  Created by Anton Begehr on 07.04.19.
//  Copyright © 2019 Anton Begehr. All rights reserved.
//

import UIKit
import HMKit
import AutoAPI
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // request notifications permissions
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound])
        { (granted, error) in
            if error != nil {
                print("ERROR requesting notification persmissions: ", error as Any)
            }
        }
        
        // HM: initialise SDK
        do {
            try HMKit.shared.initialise(
                deviceCertificate: "dGVzdIqd2u1msODVCoJbt/BLBqG4DB1L5eJZA+fNJ/zI1l9GW1hOtSsEygFLy5mEbnMiFOCgAbhRYQ6tmWZpG5OTnR6CVeWgO/LzX5g3f8r1Pay0ZgyBQCyS0FmcJDT+zTY1dQlhIL5fvelX2Dfby6u1ZqzVfNv3qRoZ19svuhKLE4j347h2gfZIx4nLbSDScBNs9CLyS6z3",
                devicePrivateKey: "n0rSwwnIh/xEL1g+/vzRrC8ppeFNNFmub89ZwoKXcMw=",
                issuerPublicKey: "0jlGCM5MByg3xQOgmHXD51W2srXTNAccZz1lwSLOXtBqW9aOXUOCJjgCfL6m4ktMie4NX6dBr/Ehc1ogH0b9gw=="
            )
        }
        catch {
            // Handle the error
            print("Invalid initialisation parameters, please double-check the snippet: \(error)")
        }
        
        // HM: connect to vehicle
        do {
            try HMTelematics.downloadAccessCertificate(accessToken: "96c54e9b-48d2-437e-b658-630f3ea7d424") {
                switch $0 {
                case .failure(let failureReasonString):
                    // Handle the failure
                    print("HM ERROR – could  not connect to vehicle: ", failureReasonString)
                    
                case .success(_ /*let vehicleSerialData*/):
                    // Handle the success
                    print("HM – successfully connected to vehicle")
                }
            }
        }
        catch {
            // Handle the error
            print("Invalid Access Token, please double-check the string: \(error)")
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        print("received notification response")
        // todo: check the notification type before starting AC
        
        // set AC to 21°C
        
        // HM: check if vehicle certificate is registered
        if (HMKit.shared.registeredCertificates.count >= 0) {
            let vehicleSerialData = HMKit.shared.registeredCertificates[0].gainingSerial
            
            do {
                try HMTelematics.sendCommand(AAClimate.startStopHVAC(.active).bytes , serial: vehicleSerialData) { response in
                    if case HMTelematicsRequestResult.success(let data) = response {
                        guard let data = data else {
                            return print("ERROR Missing response data")
                        }
                        
                        // parse
                        guard let response = AutoAPI.parseBinary(data) as? AAVehicleLocation else {
                            return print("ERROR Failed to parse Auto API")
                        }
                        
                        print("Successfully activated HVAC: \(response)")
                    }
                    else {
                        print("ERROR Failed to activate HVAC: \(response).")
                    }
                }
            }
            catch {
                print("ERROR Failed to send command:", error)
            }
        }
    }

}

