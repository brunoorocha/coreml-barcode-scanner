//
//  ApiService.swift
//  core-ml-project
//
//  Created by Bruno Rocha on 04/07/19.
//  Copyright © 2019 Bruno Rocha. All rights reserved.
//

import Foundation

struct ApiService {
    let apiKey = "h4RKsXetEOLWjrZpqtmPfw"
    let apiUrl = "https://api.cosmos.bluesoft.com.br"
    
    func request<T: Decodable>(on endpoint: String, completion: @escaping (T?, Error?) -> (Void)) {
        let session = URLSession.shared
        guard let url = URL(string: "\(apiUrl)\(endpoint)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod  = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "X-Cosmos-Token")
        
        let task = session.dataTask(with: request) { (data, reponse, error) in
            guard let responseData = data, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            do {

                let decodedObject = try JSONDecoder().decode(T.self, from: responseData)
                DispatchQueue.main.async {
                    completion(decodedObject, nil)
                }
            }
            catch let decodeError {
                DispatchQueue.main.async {
                    completion(nil, decodeError)
                }
            }
        }
        
        task.resume()
    }
}
