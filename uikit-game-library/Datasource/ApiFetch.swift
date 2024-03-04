//
//  ApiFetch.swift
//  uikit-game-library
//
//  Created by Bisma S Wasesasegara on 05/03/24.
//

import Foundation

class ApiFetch {
    lazy private var session = URLSession.shared
    
    var task: URLSessionTask? { _task }
    private var _task: URLSessionTask?
    
    func call<T>(_ method: Method, url: String, parameters: [String: Any]? = nil, responseType: T.Type?, completion: @escaping (Result<T?, NetworkError>) -> Void) throws where T: Decodable {
        guard let baseUrl = URL(string: url) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var urlComponents = URLComponents(url: baseUrl, resolvingAgainstBaseURL: false)
        if let params = parameters {
            urlComponents?.queryItems = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        }
        
        guard let url = urlComponents?.url else {
            completion(.failure(.invalidURL))
            return
        }
        
        _task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(
                    .failure(
                        .requestFailed(
                            NSError(
                                domain: "",
                                code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                                userInfo: nil
                            )
                        )
                    )
                )
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            guard responseType != nil else {
                completion(.success(nil))
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(.parseFailed))
            }
        }
        task?.resume()
    }
    
    enum NetworkError: Error {
        case invalidURL
        case noData
        case requestFailed(Error)
        case parseFailed
    }
    
    enum Method {
        case get
    }
}
