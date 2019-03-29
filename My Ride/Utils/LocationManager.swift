//
// Created by Liat Grinshpun on 2019-03-16.
// Copyright (c) 2019 Liat Grinshpun. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationManagerDelegate {
    func didUpdateLocation(_ location: CLLocation)
}

class LocationManager: NSObject, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()
    var currentLocation: CLLocation!

    var delegate: LocationManagerDelegate?

    func requestAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined, .denied:
            // Request when-in-use authorization initially
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    func start() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined, .denied, .restricted:
            return
        default:
            break;
        }

        // Do not start services that aren't available.
        if !CLLocationManager.locationServicesEnabled() {
            // Location services is not available.
            return
        }

        // Configure and start the service.
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100.0  // In meters.
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }


    // CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let lastLocation = locations.last else {
            return
        }

        if !lastLocation.isEqual(currentLocation) {
            currentLocation = lastLocation
            delegate?.didUpdateLocation(currentLocation)
        }
    }
}
