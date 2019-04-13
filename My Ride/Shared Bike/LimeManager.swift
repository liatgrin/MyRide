//
// Created by Liat Grinshpun on 2019-04-06.
// Copyright (c) 2019 Liat Grinshpun. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class LimeManager: SharedBikeProtocol {

    static var sharedInstance: SharedBikeProtocol = LimeManager()

    private static let tokenKey = "lime_token"
    private static let cookieKey = "lime_cookie"

    private static let baseURL = "https://web-production.lime.bike/api/rider/v1"
    private static let loginPath = "/login"
    private static let scooterPath = "/views/map"

    private let phoneNumber = "+972547616895"
//    private let otpCode = "497332"

    var delegate: SharedBikeDelegate? = nil

    private let fetchDataQueue = DispatchQueue(label: "lime_fetch_data")
    private var isFetchingData = false;

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
            print("got nil token - can't retrieve limes")
            completion([])
            return
        }

        let cookies = HTTPCookieStorage.shared.cookies(for: URL(string: LimeManager.baseURL + LimeManager.loginPath)!) ?? []
        var headers = HTTPCookie.requestHeaderFields(with: cookies)
        headers["Authorization"] = "Bearer \(token)"

        let lat = location.coordinate.latitude
        let long = location.coordinate.longitude
        let url = LimeManager.baseURL
                + LimeManager.scooterPath
                + "?user_latitude=\(lat)&user_longitude=\(long)&zoom=16"
                + "&ne_lat=32.09582365933113&ne_lng=34.78659935295582&sw_lat=32.0795346338774&sw_lng=34.77771587669849"

        NetworkManager.getRequest(url: URL(string: url)!, headers: headers, body: nil) { data in

            guard let data = data else {
                completion([])
                return
            }

            let limes = self.parseGetScootersResponse(jsonData: data)
            completion(limes)
        }
    }

    private func parseGetScootersResponse(jsonData: Data) -> [BikeModel] {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let dataObject = jsonObject["data"] as? [String: Any],
              let attributesObject = dataObject["attributes"] as? [String: Any],
              let bikesObject = attributesObject["bikes"] as? [[String: Any]]
                else {
            print("parsing lime response failed")
            return []
        }

        let limes: [BikeModel] = bikesObject.map { lime in
            let attributes = lime["attributes"] as! [String: Any]
            return BikeModel(id: lime["id"] as! String,
                    latitude: attributes["latitude"] as! Double,
                    longitude: attributes["longitude"] as! Double,
                    bikeType: .Lime)
        }
        return limes
    }

    private func getAuthToken(_ completion: @escaping (_ token: String?) -> ()) {
        let token = UserDefaults.standard.string(forKey: LimeManager.tokenKey)
        if token == nil {
            self.requestOTP { otp in
                self.requestAuthToken(with: otp, completion)
            }
        } else {
            completion(token)
        }
    }

    private func requestAuthToken(with otpCode: String?, _ completion: @escaping (_ token: String?) -> ()) {
        let headers = ["content-type": "application/json"]
        let body = try! JSONSerialization.data(withJSONObject: ["login_code": otpCode, "phone": phoneNumber])

        NetworkManager.postRequest(url: URL(string: LimeManager.baseURL + LimeManager.loginPath)!,headers: headers, body: body) { data in
            if let data = data, let token = self.parseAuthenticationResponse(jsonData: data) {
                UserDefaults.standard.set(token, forKey: LimeManager.tokenKey)
                completion(token)
            }
            else {
                completion(nil)
            }
        }
    }

    private func parseAuthenticationResponse(jsonData: Data) -> String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
                else {
            print("parsing lime auth token response failed")
            return nil
        }

        return jsonObject["token"] as? String
    }

    private func requestOTP(_ completion: @escaping (_ otp: String?) -> ()) {
        let encodedPhoneNumber = phoneNumber.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        NetworkManager.getRequest(url: URL(string: "\(LimeManager.baseURL)\(LimeManager.loginPath)?phone=\(encodedPhoneNumber ?? phoneNumber)")!, headers: nil, body: nil) { _ in
            let alert = UIAlertController(title: "SMS Code", message: "Please enter the code", preferredStyle: .alert)

            alert.addTextField()

            alert.addAction(UIAlertAction(title: "Done", style: .default) { action in
                let textField = alert.textFields![0]
                completion(textField.text)
            })

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in 
                completion(nil)
            })

            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
        }
    }
}
