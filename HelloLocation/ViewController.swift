//
//  ViewController.swift
//  HelloLocation
//
//  Created by Yuuki Nishiyama on 2019/02/14.
//  Copyright © 2019 Yuuki Nishiyama. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController{
    
    @IBOutlet weak var sensingSwitch: UISwitch!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var locationSensor:LocationSensor? = nil
    var locationUpdateObserver:Any? = nil
    
    var distance:Double = 0
    
    override func viewDidLoad() {
        // get location sensor instance from AppDelegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.locationSensor = appDelegate.locationSensor
    
        if UserDefaults.standard.bool(forKey: LocationSensor.SENSOR_LOCATION_SETTING_STATUS) {
            self.sensingSwitch.isOn = true
        }else{
            self.sensingSwitch.isOn = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.didChangeDatePicker(datePicker)
        let notificationCenter = NotificationCenter.default
        locationUpdateObserver = notificationCenter.addObserver(forName: .sensorLocationNewLocations ,
                                                               object: nil,
                                                               queue: .main) { (notification) in
                                                                
                                                let calendar = Calendar.current
                                                let selecedDate = self.datePicker!.date.roundDate(calendar: calendar)
                                                let today = Date().roundDate(calendar: calendar)
                                                if selecedDate != today {
                                                    return
                                                }
                                                                
                                                if let userInfo = notification.userInfo as? [String:CLLocation] {
                                                    let key = LocationSensor.SENSOR_LOCATION_NOTIFICATION_LABEL_DATA
                                                    if let location = userInfo[key] {
                                                        let latitude = location.coordinate.latitude
                                                        let longitude = location.coordinate.longitude
                                                        let anotation = MKPointAnnotation()
                                                        anotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                                        self.mapView!.addAnnotation(anotation)
                                                        // self.mapView!.showAnnotations(self.mapView!.annotations, animated: true)
                                                    }
                                                }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if let observer = locationUpdateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    @IBAction func didChangeSensingSwitch(_ sender: UISwitch) {
        if sender.isOn { // start sensor
            switch CLLocationManager.authorizationStatus(){
            case .authorizedAlways,.authorizedWhenInUse,.notDetermined:
                UserDefaults.standard.set(true,
                                          forKey: LocationSensor.SENSOR_LOCATION_SETTING_STATUS)
                self.locationSensor!.start()
                self.didChangeDatePicker(datePicker)
            case .restricted,.denied:
                sender.isOn = false
                break
            }
        }else{ // stop sensor
            self.locationSensor!.stop()
            UserDefaults.standard.set(false,
                                      forKey: LocationSensor.SENSOR_LOCATION_SETTING_STATUS)
        }
    }
    
    @IBAction func didChangeDatePicker(_ sender: UIDatePicker) {
        // print(datePicker.date)

        if let sensor = self.locationSensor{
            if let locations = sensor.getLocations(on: datePicker.date){
                // remove annotations
                mapView!.removeAnnotations(mapView!.annotations)
                
                // make and add annotations
                for location in locations {
                    let anotation = MKPointAnnotation()
                    anotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude,
                                                                  longitude: location.longitude)
                    mapView!.addAnnotation(anotation)
                }
                
                // change the map scale
                mapView!.showAnnotations(mapView!.annotations, animated: true)
            }
        }
    }
}

extension Date {
    func roundDate(calendar cal: Calendar) -> Date {
        let year  = cal.component(.year, from: self)
        let month = cal.component(.month, from: self)
        let day   = cal.component(.day, from: self)
        return cal.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
