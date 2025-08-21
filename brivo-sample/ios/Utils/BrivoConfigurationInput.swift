//
//  BrivoConfigurationInput.swift
//  brivo
//
//  Created by Adrian Somesan on 12.03.2025.
//

struct BrivoConfigurationInput: Decodable {
  let clientId: String
  let clientSecret: String
  let useSDKStorage: Bool
}
