//
//  BrivoSDKModule.m
//  brivo
//
//  Created by Adrian Somesan on 05.03.2025.
//

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RCT_EXTERN_MODULE(BrivoSDKModule, RCTEventEmitter)

RCT_EXTERN_METHOD(init:(NSString *)brivoConfigurationJson
                  onSuccess:(RCTPromiseResolveBlock)resolve
                  onFailed:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getVersion:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(redeemPass:(NSString *)passId
                  passCode:(NSString *)passCode
                  onSuccess:(RCTPromiseResolveBlock)resolve
                  onFailed:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(retrieveSDKLocallyStoredPasses:(RCTPromiseResolveBlock)resolve
                  onFailed:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(unlockAccessPoint:(NSString *)passId
                  accessPointId:(NSString *)accessPointId)

RCT_EXTERN_METHOD(refreshPass:(NSString *)brivoTokensJSON
                  onSuccess:(RCTPromiseResolveBlock)resolve
                  onFailed:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(unlockNearestAccessPoint)

@end
