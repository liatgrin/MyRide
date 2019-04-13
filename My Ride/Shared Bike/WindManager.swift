//
// Created by Liat Grinshpun on 2019-03-29.
// Copyright (c) 2019 Liat Grinshpun. All rights reserved.
//

import Foundation
import CoreLocation

class WindManager: SharedBikeProtocol {

    static var sharedInstance: SharedBikeProtocol = WindManager()

    var delegate: SharedBikeDelegate? = nil

    func getBikes(around location: CoreLocation.CLLocation) {
        NetworkManager.getRequest(url: URL(string: "https://api-prod.ibyke.io/v2/boards?latitude=\(location.coordinate.latitude)&longitude=\(location.coordinate.longitude)")!,
                headers: nil, body: nil) { data in
            guard let data = data else {
                return
            }

            let winds = self.parseResponse(jsonData: data)
            self.delegate?.didRetrieveBikeInfo(winds)
        }
    }

    private func parseResponse(jsonData: Data) -> [BikeModel] {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let windObject = jsonObject["items"] as? [[String: Any]]
                else {
            print("parsing wind response failed")
            return []
        }

        let winds = windObject.map { BikeModel(id: $0["boardId"] as! String,
                latitude: Double($0["latitude"] as! String)!,
                longitude: Double($0["longitude"] as! String)!,
                bikeType: .Wind) }
        return winds
    }
}
