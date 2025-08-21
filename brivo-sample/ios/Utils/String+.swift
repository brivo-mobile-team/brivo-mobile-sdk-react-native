//
//  String+.swift
//  brivo
//
//  Created by Adrian Somesan on 11.03.2025.
//

extension String {
  func decoded<T: Decodable>(as type: T.Type) throws -> T {
    guard let data = self.data(using: .utf8) else {
      throw NSError(domain: "StringDecodingError", code: -1, userInfo: nil)
    }
    return try JSONDecoder().decode(T.self, from: data)
  }
}
