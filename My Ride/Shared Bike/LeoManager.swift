//
// Created by Liat Grinshpun on 2019-03-30.
// Copyright (c) 2019 Liat Grinshpun. All rights reserved.
//

import Foundation
import CoreLocation

class LeoManager: SharedBikeProtocol {

    static var sharedInstance: SharedBikeProtocol = LeoManager()

    var delegate: SharedBikeDelegate? = nil

    func getBikes(around location: CoreLocation.CLLocation) {
        NetworkManager.getRequest(url: URL(string: "https://mobile.leoriders.com/leo/app/get_markers.php")!,
                headers: nil, body: nil) { data in
            guard let data = data else {
                return
            }

            let leos = self.parseResponse(jsonData: data)
            self.delegate?.didRetrieveBikeInfo(leos)
        }
    }

    private func parseResponse(jsonData: Data) -> [BikeModel] {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let leoObject = jsonObject["data"] as? [[String: Any]]
                else {
            print("parsing wind response failed")
            return []
        }

        let leos = leoObject.map { BikeModel(id: $0["SCOOTER_ID"] as! String,
                latitude: Double($0["LAT1"] as! String)!,
                longitude: Double($0["LONG1"] as! String)!,
                bikeType: .Leo) }
        return leos
    }
}
