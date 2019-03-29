//
//  SharedBikeProtocol.swift
//  My Ride
//
//  Created by Liat Grinshpun on 03/16/2019.
//  Copyright © 2019 Liat Grinshpun. All rights reserved.
//

import CoreLocation

protocol SharedBikeProtocol {
    static var sharedInstance: SharedBikeProtocol { get }
    var delegate: SharedBikeDelegate? { get set }
    func getBikes(around location: CLLocation)
}

protocol SharedBikeDelegate {
    func didRetrieveBikeInfo(_ bikes: [BikeModel])
}
