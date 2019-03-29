//
// Created by Liat Grinshpun on 2019-03-23.
// Copyright (c) 2019 Liat Grinshpun. All rights reserved.
//

import Foundation

class NetworkManager {

    static func postRequest(url: URL, headers: [String: String]?, body: Data?, completion: @escaping (Data?) -> ()) {
        sendRequest(httpMethod: "POST", url: url, headers: headers, body: body, completion: completion)
    }

    static func getRequest(url: URL, headers: [String: String]?, body: Data?, completion: @escaping (Data?) -> ()) {
        sendRequest(httpMethod: "GET", url: url, headers: headers, body: body, completion: completion)
    }

    private static func sendRequest(httpMethod: String, url: URL, headers: [String: String]?, body: Data?, completion: @escaping (Data?) -> ()) {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.allHTTPHeaderFields = headers
        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let response = response as? HTTPURLResponse, error == nil else {  // check for fundamental networking error
                print("error", error ?? "Unknown error")
                return
            }

            guard (200 ... 299) ~= response.statusCode else { // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }

            completion(data)
        }
        task.resume()
    }
}
