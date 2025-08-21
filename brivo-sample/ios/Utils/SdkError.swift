//
//  SdkError.swift
//  brivo
//
//  Created by Adrian Somesan on 12.03.2025.
//

import BrivoCore

enum SdkError: Error, CustomNSError {
  case failedToParseJSON
  case missingClientIdClientSecretOrUseSDKStorage
  case missingBrivoSDKConfiguration
  case sdkNotConfigured
  case missingValidPassId
  case missingValidPassCode
  case jsonNotDictionary
  case missingTokensInJSON
  case failedToCreateBrivoTokens
  case refreshError(BrivoError)
  case invalidJSON
  case missingTokens

  var errorCode: Int {
    switch self {
    case .failedToParseJSON:
      return -1001
    case .missingClientIdClientSecretOrUseSDKStorage:
      return -1002
    case .missingBrivoSDKConfiguration:
      return -1003
    case .sdkNotConfigured:
      return -1004
    case .missingValidPassId:
      return -1005
    case .missingValidPassCode:
      return -1006
    case .jsonNotDictionary:
      return -1007
    case .missingTokensInJSON:
      return -1008
    case .failedToCreateBrivoTokens:
      return -1009
    case .refreshError(let brivoError):
      return (brivoError as NSError).code
    case .invalidJSON:
      return -1010
    case .missingTokens:
      return -1011
    }
  }

  var errorUserInfo: [String: Any] {
    let message: String
    switch self {
    case .failedToParseJSON:
      message = "Failed to parse JSON"
    case .missingClientIdClientSecretOrUseSDKStorage:
      message = "Missing clientId, clientSecret or useSDKStorage"
    case .missingBrivoSDKConfiguration:
      message = "Failed to initialize BrivoSDKConfiguration"
    case .sdkNotConfigured:
      message = "SDK not configured"
    case .missingValidPassId:
      message = "Please enter a valid passId"
    case .missingValidPassCode:
      message = "Please enter a valid passCode"
    case .jsonNotDictionary:
      message = "JSON is not a dictionary"
    case .missingTokensInJSON:
      message = "Missing tokens in JSON"
    case .failedToCreateBrivoTokens:
      message = "Failed to create BrivoTokens"
    case .refreshError(let brivoError):
      message = brivoError.localizedDescription
    case .invalidJSON:
      message = "Invalid JSON"
    case .missingTokens:
      message = "Missing tokens"
    }
    return [NSLocalizedDescriptionKey: message]
  }

  var errorUserInfoKey: [String : Any] {
    return self.errorUserInfo
  }

  var userInfo: [String : Any] {
    return self.errorUserInfo
  }
}
