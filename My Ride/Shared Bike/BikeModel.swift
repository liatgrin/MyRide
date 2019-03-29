//
// Created by Liat Grinshpun on 2019-03-22.
// Copyright (c) 2019 Liat Grinshpun. All rights reserved.
//

import Foundation

enum BikeType: String {
    case Mobike
    case Bird
}

struct BikeModel {

    var id: String
    let latitude: Double
    let longitude: Double
    let bikeType: BikeType

    init(id: String, latitude: Double, longitude: Double, bikeType: BikeType) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.bikeType = bikeType
    }
}
