//
// Created by Liat Grinshpun on 2019-03-23.
// Copyright (c) 2019 Liat Grinshpun. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class BirdManager: SharedBikeProtocol {

    static var sharedInstance: SharedBikeProtocol = BirdManager()

    private static let tokenKey = "bird_token"
    private static let emailKey = "bird_email"

    var delegate: SharedBikeDelegate?

    func getBikes(around location: CoreLocation.CLLocation) {
        getAuthToken { token in
            self.getBikes(around: location, token: token) { bikes in
                self.delegate?.didRetrieveBikeInfo(bikes)
            }
        }
    }

    private func getBikes(around location: CoreLocation.CLLocation, token: String?, completion: @escaping ([BikeModel]) -> ()) {
        guard let token = token else {
            print("got nil token - can't retrieve birds")
            completion([])
            return
        }

        let locationHeader: [String: Double] = ["latitude": location.coordinate.latitude,
                              "longitude": location.coordinate.longitude,
                              "altitude": 500,
                              "accuracy": 100,
                              "speed": -1,
                              "heading": -1]
        let locationHeaderJson = String(data: try! JSONSerialization.data(withJSONObject: locationHeader), encoding: .utf8)
        let headers = ["Authorization": "Bird \(token)",
                       "Device-id": UIDevice().identifierForVendor!.uuidString,
                       "App-Version": "3.0.5",
                       "Location": locationHeaderJson!]

        NetworkManager.getRequest(url: URL(string: "https://api.bird.co/bird/nearby?latitude=\(location.coordinate.latitude)&longitude=\(location.coordinate.longitude)&radius=100")!,
                headers: headers, body: nil) { data in
            guard let data = data else {
                completion([])
                return
            }

            let birds = self.parseGetNearbyResponse(jsonData: data)
            completion(birds)
        }

    }

    private func parseGetNearbyResponse(jsonData: Data) -> [BikeModel] {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let birdsObject = jsonObject["birds"] as? [[String: Any]]
                else {
            print("parsing mobike response failed")
            return []
        }

        let birds: [BikeModel] = birdsObject.map { bird in
            let location = bird["location"] as! [String: Double]
            return BikeModel(id: bird["id"] as! String,
                latitude: location["latitude"]!,
                longitude: location["longitude"]!,
                bikeType: .Bird)
        }
        return birds
    }

    private func getAuthToken(_ completion: @escaping (String?) -> ()) {
        if let token = UserDefaults.standard.string(forKey: BirdManager.tokenKey) {
            completion(token)
        }
        else {
            let headers = ["Content-type": "application/json",
                           "Platform": "ios",
                           "Device-id": UIDevice().identifierForVendor!.uuidString]
            let body = try! JSONSerialization.data(withJSONObject: ["email": getEmail()])

            NetworkManager.postRequest(url: URL(string: "https://api.bird.co/user/login")!, headers: headers, body: body) { data in

                guard let data = data else {
                    completion(nil)
                    return
                }

                let responseString = String(data: data, encoding: .utf8)!
                print("responseString = \(responseString)")

                let token = self.parseAuthTokenResponse(jsonData: data)
                UserDefaults.standard.set(token, forKey: BirdManager.tokenKey)
                completion(token)
            }
        }
    }

    private func parseAuthTokenResponse(jsonData: Data) -> String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String]
                else {
            print("parsing bird auth token response failed")
            return nil
        }

        return jsonObject["token"]
    }

    private func getEmail() -> String {
        if let email = UserDefaults.standard.string(forKey: BirdManager.emailKey) {
            return email
        }

        let email = "\(UIDevice().identifierForVendor!.uuidString.prefix(8))@myride.com"
        UserDefaults.standard.set(email, forKey: BirdManager.emailKey)
        return email
    }

}
