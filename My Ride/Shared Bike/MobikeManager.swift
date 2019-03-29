//
// Created by Liat Grinshpun on 2019-03-22.
// Copyright (c) 2019 Liat Grinshpun. All rights reserved.
//

import Foundation
import CoreLocation

class MobikeManager: SharedBikeProtocol {

    static var sharedInstance: SharedBikeProtocol = MobikeManager()

    var delegate: SharedBikeDelegate?

    func getBikes(around location: CLLocation) {
        let headers = ["platform": "1",
                       "Content-Type": "application/x-www-form-urlencoded"]
        let body = "latitude=\(location.coordinate.latitude)&longitude=\(location.coordinate.longitude)"
        NetworkManager.postRequest(url: URL(string: "http://app.mobike.com/api/nearby/v4/nearbyBikeInfo")!, headers: headers, body: body.data(using: .utf8)) { data in
            guard let data = data else {
                return
            }

            let bikes = self.parseResponse(jsonData: data)
            self.delegate?.didRetrieveBikeInfo(bikes)
        }
    }

    private func parseResponse(jsonData: Data) -> [BikeModel] {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let bikesObject = jsonObject["bike"] as? [[String: Any]]
                else {
            print("parsing mobike response failed")
            return []
        }

        let bikes = bikesObject.map { BikeModel(id: $0["bikeIds"] as! String,
                                            latitude: $0["distY"] as! Double,
                                            longitude: $0["distX"] as! Double,
                                            bikeType: .Mobike) }
        return bikes
    }
}
