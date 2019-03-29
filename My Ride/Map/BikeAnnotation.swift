//
// Created by Liat Grinshpun on 2019-03-29.
// Copyright (c) 2019 Liat Grinshpun. All rights reserved.
//

import Foundation
import MapKit

class BikeAnnotation: NSObject, MKAnnotation {

    private let bikeModel: BikeModel
    internal let coordinate: CLLocationCoordinate2D

    init(bikeModel: BikeModel) {
        self.bikeModel = bikeModel
        self.coordinate = CLLocationCoordinate2DMake(bikeModel.latitude, bikeModel.longitude)
    }

    var title: String? {
        return self.bikeModel.bikeType.rawValue
    }

    func colorForType() -> UIColor {
        switch self.bikeModel.bikeType {
        case .Mobike:
            return .orange
        case .Bird:
            return .black
        }
    }
}
