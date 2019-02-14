//
//  LocationSensor.swift
//  HelloLocation
//
//  Created by Yuuki Nishiyama on 2019/02/14.
//  Copyright © 2019 Yuuki Nishiyama. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation


extension Notification.Name{
    public static let sensorLocationNewLocations = Notification.Name("sensor.location.new_locations")
}

public class LocationSensor:NSObject{

    public static let SENSOR_LOCATION_SETTING_STATUS = "sensor.location.setting.status"
    public static let SENSOR_LOCATION_NOTIFICATION_LABEL_DATA = "data"
    
    public let locationManager = CLLocationManager()
    public var lastLocation:CLLocation?
    public var status:Bool = false
    
    override init() {
        super.init()
        /**
         set sensor settings for background sensing
         */
        locationManager.delegate = self
        // locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.distanceFilter = 100
        if #available(iOS 11.0, *) {
            locationManager.showsBackgroundLocationIndicator = false
        }
    }
    
    public func start(){
        // print(#function)
        switch CLLocationManager.authorizationStatus(){
        case .notDetermined:
            // print("send request")
            locationManager.requestAlwaysAuthorization()
            return
        case .restricted, .denied:
            return
        case .authorizedWhenInUse, .authorizedAlways:
            // print("start sensor")
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
            status = true
            break
        }
    }
    
    public func stop(){
        // print(#function)
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        status = false
    }
}

extension LocationSensor: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //  print(#function)
        switch status {
        case .authorizedAlways,.authorizedWhenInUse:
            // print("authorized")
            self.start()
            break
        default:
            // print("not authorized")
            self.stop()
            break
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.saveLocations(locations)
    }

    public func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        // print(#function)
    }

    public func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        // print(#function)
    }
}

extension LocationSensor {
    
    func saveLocations(_ locations:[CLLocation]){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let moc = appDelegate.persistentContainer.viewContext
        
        for location in locations {
            let entity = NSEntityDescription.insertNewObject(forEntityName: "Location", into: moc) as! Location
            
            entity.timestamp = Date.init()
            entity.latitude = location.coordinate.latitude
            entity.longitude = location.coordinate.longitude
            entity.accuracy = location.horizontalAccuracy
            entity.speed = location.speed
            if let lLocation = self.lastLocation {
                entity.distance = location.distance(from: lLocation)
            }else{
                entity.distance = 0
            }
            self.lastLocation = location
            
            NotificationCenter.default.post(name: .sensorLocationNewLocations,
                                            object: self,
                                            userInfo: [LocationSensor.SENSOR_LOCATION_NOTIFICATION_LABEL_DATA:location])
        }
        
        do {
            try moc.save()
        }catch{
            print("\(error)")
        }
    }
    
    func getLocations(on date:Date) -> [Location]? {
        // get the current calendar
        let calendar = NSCalendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        // get 00:00:00 today
        components.hour = 00
        components.minute = 00
        components.second = 00
        let startDate = calendar.date(from: components)
        
        // get 23:59:59 today
        components.hour = 23
        components.minute = 59
        components.second = 59
        let endDate = calendar.date(from: components)
        
        // get AppDelegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let moc = appDelegate.persistentContainer.viewContext
        
        // make a fetch request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        fetchRequest.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp =< %@", argumentArray: [startDate!, endDate!])
        do {
            // fetch location data using the query
            let locations = try moc.fetch(fetchRequest) as! [Location]
            // print("\(locations.count) records")
            
           return locations
        }catch {
            print("\(error)")
        }
        return nil
    }
}
