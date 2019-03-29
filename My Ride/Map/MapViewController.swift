//
//  ViewController.swift
//  My Ride
//
//  Created by Liat Grinshpun on 03/04/2019.
//  Copyright © 2019 Liat Grinshpun. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, LocationManagerDelegate, SharedBikeDelegate, MKMapViewDelegate {

    private static let bikeAnnotationReuseId = "bike_annotation"

    @IBOutlet private weak var mapView: MKMapView!

    private let locationManager = LocationManager()

    private let sharedBikeManagers: [SharedBikeProtocol] = [MobikeManager.sharedInstance, BirdManager.sharedInstance]

    // Tel Aviv: 32.0853° N, 34.7818° E

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self

        MobikeManager.sharedInstance.delegate = self
        BirdManager.sharedInstance.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        locationManager.requestAuthorization()
        locationManager.start()
    }

}

// MKMapViewDelegate

extension MapViewController {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation is MKUserLocation) {
            return nil
        }

        guard let annotation = annotation as? BikeAnnotation else {
            return nil
        }

        let view = mapView.dequeueReusableAnnotationView(withIdentifier: MapViewController.bikeAnnotationReuseId) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: nil, reuseIdentifier: MapViewController.bikeAnnotationReuseId)

        view.annotation = annotation
        view.markerTintColor = annotation.colorForType()
        return view
    }
}


// SharedBikeDelegate

extension MapViewController {

    func didRetrieveBikeInfo(_ bikes: [BikeModel]) {
        var annotations: [BikeAnnotation] = []

        for bike in bikes {
            let annotation = BikeAnnotation(bikeModel: bike)

            annotations.append(annotation)
        }

        mapView.addAnnotations(annotations)
    }
}


// LocationManagerDelegate

extension MapViewController {

    func didUpdateLocation(_ location: CLLocation) {
        centerMapOnLocation(location)

        for sharedBikeManager in sharedBikeManagers {
            sharedBikeManager.getBikes(around: location)
        }
    }

    private func centerMapOnLocation(_ location: CLLocation) {
        let viewRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
        mapView.setRegion(viewRegion, animated: false)
    }
}

