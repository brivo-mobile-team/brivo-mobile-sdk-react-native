//
//  BrivoReactNativeSdk.swift
//  brivo
//
//  Created by Adrian Somesan on 05.03.2025.
//

import Foundation
import BrivoCore
import BrivoOnAir
import BrivoAccess

@objc(BrivoSDKModule)
class BrivoSDKModule: RCTEventEmitter {

  @MainActor var cancellationTimer: Timer?

  override init() {
    super.init()
  }

  @objc(init:onSuccess:onFailed:)
  init(
    brivoConfigurationJson: String,
    onSuccess: @escaping RCTPromiseResolveBlock,
    onFailed: @escaping RCTPromiseRejectBlock
  ) {
    super.init()


    do {
      let configInput = try brivoConfigurationJson.decoded(as: BrivoConfigurationInput.self)

      let brivoConfig = try BrivoSDKConfiguration(
        clientId: configInput.clientId,
        clientSecret: configInput.clientSecret,
        useSDKStorage: configInput.useSDKStorage,
        shouldPromptForContinuation: true,
        authUrl: nil,
        apiUrl: nil,
        smartHomeUrl: nil,
        smartHomeUrlV1: nil,
        smartHomeUrlV4: nil
      )
      BrivoSDK.instance.configure(brivoConfiguration: brivoConfig)
      onSuccess("SDK initialized successful")
    } catch {
      let error = SdkError.missingBrivoSDKConfiguration
      onFailed(String(error.errorCode), error.localizedDescription, error)
    }
  }

  @objc(getVersion:reject:)
  func getVersion(_ resolve: @escaping RCTPromiseResolveBlock,
                  reject: @escaping RCTPromiseRejectBlock) {
    resolve(BrivoSDK.sdkVersion)
  }

  @objc(redeemPass:passCode:onSuccess:onFailed:)
  func redeemPass(_ passId: String,
                  passCode: String,
                  onSuccess resolve: @escaping RCTPromiseResolveBlock,
                  onFailed reject: @escaping RCTPromiseRejectBlock) {
    if passId.isEmpty {
      let error = SdkError.missingValidPassId
      reject(ConstantsForSDK.brivoSDKLoggerTag, error.localizedDescription, error)
      return
    }

    if passCode.isEmpty {
      let error = SdkError.missingValidPassCode
      reject(ConstantsForSDK.brivoSDKLoggerTag, error.localizedDescription, error)
      return
    }

    Task {
      do {
        let onAirResult = try await BrivoSDKOnAir.instance().redeemPass(passId: passId,
                                                                        passCode: passCode)
        switch onAirResult {
        case .success(let pass):
          resolve(pass?.asJsonString ?? "")
        case .failure(let error):
          reject(
            ConstantsForSDK.brivoSDKLoggerTag,
            error.localizedDescription,
            error
          )
        }
      } catch {
        reject(
          ConstantsForSDK.brivoSDKLoggerTag,
          error.localizedDescription,
          error
        )
      }
    }
  }

  @objc(retrieveSDKLocallyStoredPasses:onFailed:)
  func retrieveSDKLocallyStoredPasses(
    _ resolve: @escaping RCTPromiseResolveBlock,
    onFailed reject: @escaping RCTPromiseRejectBlock
  ) {
    Task {
      let onAirResult = try await BrivoSDKOnAir.instance().retrieveSDKLocallyStoredPasses()
      switch onAirResult {
      case .success(let passes):
        let jsonString = "[" + passes.map { $0.asJsonString ?? "" }.joined(separator: ",") + "]"
        resolve(jsonString)
      case .failure(let error):
        reject(
          ConstantsForSDK.brivoSDKLoggerTag,
          error.localizedDescription,
          error
        )
      }
    }
  }

  @objc(unlockAccessPoint:accessPointId:)
  func unlockAccessPoint(_ passId: String, accessPointId: String) {
    BrivoSDKAccess.instance().turnOnCentral()
    let sdkAccess = BrivoSDKAccess.instance()

    Task { @MainActor in
      let stream = await sdkAccess.unlockAccessPoint(
        passId: passId,
        accessPointId: accessPointId,
        cancellationSignal: nil
      )
      do {
        for try await result in stream {
          if self.cancellationTimer == nil {
            self.cancellationTimer = Timer.scheduledTimer(
              withTimeInterval: ConstantsForSDK.cancelationTimerInterval,
              repeats: false
            ) { timer in
              self.sendEvent(
                withName: "UnlockAccessPointUpdate",
                body: "Open door time out"
              )
            }
          }
          switch result.accessPointCommunicationState {
          case .success:
            self.resetCancellationTimer()
            self.sendEvent(
              withName: "UnlockAccessPointUpdate",
              body: "Access point unlock successful"
            )

          case .shouldContinue:
            result.shouldContinue?(true)

          case .failed:
            self.resetCancellationTimer()
            self.sendEvent(
              withName: "UnlockAccessPointUpdate",
              body: [
                "error": result.error?.localizedDescription ?? "Unknown error"
              ]
            )
          case .scanning:
            self.sendEvent(
              withName: "UnlockAccessPointUpdate",
              body: "Scanning"
            )
          default:
            print("default")
          }
        }
      } catch {
        self.resetCancellationTimer()
        self.sendEvent(
          withName: "UnlockAccessPointUpdate",
          body: [
            "error": error.localizedDescription
          ]
        )
      }
    }
  }

  @objc(refreshPass:onSuccess:onFailed:)
  func refreshPass(
    _ brivoTokensJSON: String,
    onSuccess resolve: @escaping RCTPromiseResolveBlock,
    onFailed reject: @escaping RCTPromiseRejectBlock
  ) {

    do {
      guard let jsonData = brivoTokensJSON.data(using: .utf8) else {
        throw SdkError.invalidJSON
      }

      guard let object = try JSONSerialization.jsonObject(
        with: jsonData,
        options: []
      ) as? [String: Any] else {
        throw SdkError.invalidJSON
      }

      guard let accessToken = object["accessToken"] as? String,
            let refreshToken = object["refreshToken"] as? String else {
        throw SdkError.missingTokensInJSON
      }

      let brivoTokens = BrivoTokens(
        accessToken: accessToken,
        refreshToken: refreshToken
      )

      Task {
        do {
          let result = try await BrivoSDKOnAir.instance().refreshPass(brivoTokens: brivoTokens)
          switch result {
          case .success(let pass):
            if let pass = pass {
              resolve(pass.asJsonString)
            } else {
              resolve("")
            }
          case .failure(let error):
            throw SdkError.refreshError(error)
          }
        } catch {
          reject(ConstantsForSDK.brivoSDKLoggerTag, error.localizedDescription, error)
        }
      }
    } catch {
        let sdkError: SdkError
        switch error {
        case SdkError.invalidJSON:
            sdkError = .failedToParseJSON
        case SdkError.missingTokens:
            sdkError = .missingTokensInJSON
        case SdkError.failedToCreateBrivoTokens:
            sdkError = .failedToCreateBrivoTokens
        case SdkError.refreshError(let brivoError):
            sdkError = .refreshError(brivoError)
        default:
            sdkError = .failedToParseJSON
        }
        reject(ConstantsForSDK.brivoSDKLoggerTag, sdkError.localizedDescription, sdkError)
    }
  }

  @objc(unlockNearestAccessPoint)
  func unlockNearestAccessPoint() {

    BrivoSDKAccess.instance().turnOnCentral()
    let sdkAccess = BrivoSDKAccess.instance()

    Task { @MainActor in
      let stream = await sdkAccess.unlockNearestBLEAccessPoint(cancellationSignal: nil)
      do {
        for try await result in stream {
          if self.cancellationTimer == nil {
            self.cancellationTimer = Timer.scheduledTimer(
              withTimeInterval: ConstantsForSDK.cancelationTimerInterval,
              repeats: false
            ) { timer in
              self.sendEvent(
                withName: "UnlockNearestAccessPointUpdate",
                body: "Open door time out"
              )
            }
          }

          switch result.accessPointCommunicationState {
          case .success:
            self.resetCancellationTimer()
            self.sendEvent(
              withName: "UnlockNearestAccessPointUpdate",
              body: "Access point unlock successful"
            )
            return
          case .shouldContinue:
            result.shouldContinue?(true)
          case .failed:
            self.resetCancellationTimer()
            self.sendEvent(
              withName: "UnlockNearestAccessPointUpdate",
              body: [
                "error": result.error?.localizedDescription ?? "Unknown error"
              ]
            )
            return
          case .scanning:
            self.sendEvent(
              withName: "UnlockNearestAccessPointUpdate",
              body: "Scanning"
            )
          default:
            print("default")
          }
        }
      } catch {
        self.resetCancellationTimer()
        self.sendEvent(withName: "UnlockNearestAccessPointUpdate", body: [
          "error": error.localizedDescription
        ])
      }
    }
  }

  // MARK: - Private

  @MainActor private func resetCancellationTimer() {
    self.cancellationTimer?.invalidate()
    self.cancellationTimer = nil
  }

  // MARK: - RCTBridge

  @objc override static func requiresMainQueueSetup() -> Bool {
    return true
  }

  @objc override func supportedEvents() -> [String]! {
    return ["UnlockAccessPointUpdate", "UnlockNearestAccessPointUpdate"]
  }
}
