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
    private static let tokenExpirationKey = "bird_token_expiration"
    private static let emailKey = "bird_email"

    private let fetchDataQueue = DispatchQueue(label: "bird_fetch_data")
    private var isFetchingData = false;

    var delegate: SharedBikeDelegate?

    func getBikes(around location: CLLocation) {
        fetchDataQueue.async {
            if self.isFetchingData {
                return
            }

            self.isFetchingData = true
            self.getAuthToken { token in
                self.getBikes(around: location, token: token) { bikes in
                    self.isFetchingData = false
                    self.delegate?.didRetrieveBikeInfo(bikes)
                }
            }
        }

    }

    private func getBikes(around location: CLLocation, token: String?, completion: @escaping ([BikeModel]) -> ()) {
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
            print("parsing nearby birds response failed")
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
        let token = UserDefaults.standard.string(forKey: BirdManager.tokenKey)
        guard let tokenExpiration = UserDefaults.standard.object(forKey: BirdManager.tokenExpirationKey) as? Date,
              tokenExpiration.timeIntervalSinceNow > 2, // token expiration is at least 2 seconds
              token != nil else {
            self.requestAuthentication(defaultToken: token, completion: completion)
            return
        }

        completion(token)
    }

    private func requestAuthentication(defaultToken: String?, completion: @escaping (String?) -> ()) {
        let identifier = UIDevice().identifierForVendor!.uuidString
        let headers = ["Content-type": "application/json",
                       "Platform": "ios",
                       "Device-id": identifier]
        let body = try! JSONSerialization.data(withJSONObject: ["email": "\(identifier)@myride.com"])

        NetworkManager.postRequest(url: URL(string: "https://api.bird.co/user/login")!, headers: headers, body: body) { data in

            guard let data = data else {
                completion(nil)
                return
            }

            let (token, expiration) = self.parseAuthenticationResponse(jsonData: data, defaultToken: defaultToken)
            UserDefaults.standard.set(token, forKey: BirdManager.tokenKey)
            UserDefaults.standard.set(expiration, forKey: BirdManager.tokenExpirationKey)
            completion(token)
        }
    }

    private func parseAuthenticationResponse(jsonData: Data, defaultToken: String?) -> (String?, Date?) {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String]
                else {
            print("parsing bird auth token response failed")
            return (nil, nil)
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions =  [.withInternetDateTime, .withFractionalSeconds]
        return (jsonObject["token"] ?? defaultToken, dateFormatter.date(from: jsonObject["expires_at"] ?? ""))
    }
}
