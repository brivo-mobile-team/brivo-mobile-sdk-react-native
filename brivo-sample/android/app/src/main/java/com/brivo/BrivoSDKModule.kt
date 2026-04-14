package com.brivo

import com.brivo.sdk.BrivoSDK
import com.brivo.sdk.BrivoSDKInitializationException
import com.brivo.sdk.access.BrivoSDKAccess
import com.brivo.sdk.enums.AccessPointCommunicationState
import com.brivo.sdk.enums.ServerRegion
import com.brivo.sdk.localauthentication.BrivoSDKLocalAuthentication
import com.brivo.sdk.model.BrivoConfiguration
import com.brivo.sdk.model.BrivoError
import com.brivo.sdk.model.BrivoResult
import com.brivo.sdk.model.BrivoSDKApiState
import com.brivo.sdk.onair.interfaces.IOnRetrieveSDKLocallyStoredPassesListener
import com.brivo.sdk.onair.model.BrivoOnairPass
import com.brivo.sdk.onair.model.BrivoTokens
import com.brivo.sdk.onair.repository.BrivoSDKOnair
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.google.gson.Gson
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import kotlin.coroutines.CoroutineContext
import com.brivo.sdk.logger.DefaultLoggerOutput


class BrivoSDKModule(reactApplicationContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactApplicationContext), CoroutineScope {

    private val job = SupervisorJob()
    override val coroutineContext: CoroutineContext = Dispatchers.IO + job

    private val BRIVO_SDK_ERROR: String = "BRIVO_SDK_ERROR"

    enum class EventNames{
        UnlockAccessPointUpdate,
        UnlockNearestAccessPointUpdate
    }

    private data class BrivoConfigurationInput(
        val clientId: String,
        val clientSecret: String,
        val useSDKStorage: Boolean,
        val useEuRegion: Boolean
    )

    override fun getName(): String = "BrivoSDKModule"

    @ReactMethod
    fun init(brivoConfigurationJSON: String?, promise: Promise) {
        try {
            val configInput = Gson().fromJson(
                brivoConfigurationJSON,
                BrivoConfigurationInput::class.java
            )

            if (configInput == null) {
                promise.reject(BRIVO_SDK_ERROR, "Invalid configuration JSON")
                return
            }
            
            val region = if (configInput.useEuRegion) ServerRegion.EUROPE else ServerRegion.UNITED_STATES

            val brivoConfiguration = BrivoConfiguration(
                configInput.clientId,
                configInput.clientSecret,
                configInput.useSDKStorage,
                region,
            )

            BrivoSDK.init(reactApplicationContext, brivoConfiguration)
            BrivoSDK.addLoggingOutput(DefaultLoggerOutput())

            val localAuthenticationTitle = "Please authenticate"
            val localAuthenticationMessage =
                "Please use your fingerprint or password to unlock door"
            val localAuthenticationNegativeButton = "Cancel"
            val localAuthenticationDescription = "Describe 2FA prompt"
            BrivoSDKLocalAuthentication.init(
                reactApplicationContext, localAuthenticationTitle, localAuthenticationMessage,
                localAuthenticationNegativeButton, localAuthenticationDescription
            )
            promise.resolve("SDK initialized successfully")
        } catch (e: BrivoSDKInitializationException) {
            promise.reject(BRIVO_SDK_ERROR, e.localizedMessage)
        }
    }

    @ReactMethod
    fun getVersion(promise: Promise) {
        promise.resolve(BrivoSDK.version)
    }

    @ReactMethod
    fun redeemPass(passId: String?, passCode: String?, promise: Promise) {

        if (passId.isNullOrBlank()) {
            promise.reject(BRIVO_SDK_ERROR, "Please enter a valid passId")
            return
        }

        if (passCode.isNullOrBlank()) {
            promise.reject(BRIVO_SDK_ERROR, "Please enter a valid passCode")
            return
        }
        launch {
            return@launch when (val result = BrivoSDKOnair.instance.redeemPass(passId, passCode)) {
                is BrivoSDKApiState.Failed -> {
                    promise.reject(result.brivoError.code.toString(), result.brivoError.message)
                }

                is BrivoSDKApiState.Success -> {
                    promise.resolve(Gson().toJson(result.data))
                }
            }
        }
    }

    @ReactMethod
    fun refreshPass(brivoTokensJSON: String?, promise: Promise) {
        val brivoTokens = Gson().fromJson(
            brivoTokensJSON,
            BrivoTokens::class.java
        )

        launch {
            return@launch when (val result = BrivoSDKOnair.instance.refreshPass(brivoTokens)) {
                is BrivoSDKApiState.Failed -> {
                    promise.reject(result.brivoError.code.toString(), result.brivoError.message)
                }

                is BrivoSDKApiState.Success -> {
                    promise.resolve(Gson().toJson(result.data))
                }
            }
        }

    }


    private fun sendEvent(eventName: EventNames, params: String){
        reactApplicationContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit(eventName.name,params)
    }

    @ReactMethod
    fun unlockAccessPoint( passId: String, accessPointId: String){
        val shouldContinueDefferedResult = CompletableDeferred<Boolean>()
        launch {
            BrivoSDKAccess.unlockAccessPoint(passId,accessPointId,
                shouldContinueUnlockOperation = {
                    shouldContinueDefferedResult.await()
                }).collect{ result ->
                when(result.communicationState){
                    AccessPointCommunicationState.SCANNING -> {
                        sendEvent(EventNames.UnlockAccessPointUpdate, "Scanning")
                    }
                    AccessPointCommunicationState.AUTHENTICATE -> {
                        //Present 2FA
                    }
                    AccessPointCommunicationState.SHOULD_CONTINUE -> {
                        shouldContinueDefferedResult.complete(true)
                    }
                    AccessPointCommunicationState.CONNECTING -> {
                        //Handle if needed
//                        sendEvent(EventNames.UnlockAccessPointUpdate, "Connecting")
                    }
                    AccessPointCommunicationState.COMMUNICATING -> {
                        //Handle if needed
//                        sendEvent(EventNames.UnlockAccessPointUpdate, "Communicating")
                    }
                    AccessPointCommunicationState.SUCCESS -> {
                        sendEvent(EventNames.UnlockAccessPointUpdate, "Access point unlock successful")
                    }
                    AccessPointCommunicationState.ON_CLOSEST_READER -> {
                        //Handle if needed
                    }
                    AccessPointCommunicationState.FAILED -> {
                        sendEvent(EventNames.UnlockAccessPointUpdate,
                            result.error?.message ?: "Unknown error"
                        )
                    }
                    AccessPointCommunicationState.SCANNING_COOLDOWN -> {
                        val message = result.error?.message?: "Unknown scan cooldown error"
                        sendEvent(EventNames.UnlockNearestAccessPointUpdate,
                            "$message ${result.scanCooldownDurationInSeconds} seconds"
                        )
                    }
                }
            }
        }
    }

    @ReactMethod
    fun unlockNearestAccessPoint(){
        val shouldContinueDefferedResult = CompletableDeferred<Boolean>()
        launch {
            BrivoSDKAccess.unlockNearestBLEAccessPoint(
                shouldContinueUnlockOperation = {
                    shouldContinueDefferedResult.await()
                }).collect{ result ->
                when(result.communicationState){
                    AccessPointCommunicationState.SCANNING -> {
                        sendEvent(EventNames.UnlockNearestAccessPointUpdate, "Scanning")
                    }
                    AccessPointCommunicationState.AUTHENTICATE -> {
                        //Present 2FA
                    }
                    AccessPointCommunicationState.SHOULD_CONTINUE -> {
                        shouldContinueDefferedResult.complete(true)
                    }
                    AccessPointCommunicationState.CONNECTING -> {
                        //Handle if needed
//                        sendEvent(EventNames.UnlockNearestAccessPointUpdate, "Connecting")
                    }
                    AccessPointCommunicationState.COMMUNICATING -> {
                        //Handle if needed
//                        sendEvent(EventNames.UnlockNearestAccessPointUpdate, "Communicating")
                    }
                    AccessPointCommunicationState.SUCCESS -> {
                        sendEvent(EventNames.UnlockNearestAccessPointUpdate, "Access point unlock successful")
                    }
                    AccessPointCommunicationState.ON_CLOSEST_READER -> {
                        //Handle if needed
                    }
                    AccessPointCommunicationState.FAILED -> {
                        sendEvent(EventNames.UnlockNearestAccessPointUpdate,
                            result.error?.message ?: "Unknown error"
                        )
                    }
                    AccessPointCommunicationState.SCANNING_COOLDOWN -> {
                        val message = result.error?.message?: "Unknown scan cooldown error"
                        sendEvent(EventNames.UnlockNearestAccessPointUpdate,
                            "$message ${result.scanCooldownDurationInSeconds} seconds"
                        )
                    }
                }
            }
        }
    }


    @ReactMethod
    fun retrieveSDKLocallyStoredPasses(promise: Promise) {
        when (val result = BrivoSDKOnair.instance.retrieveSDKLocallyStoredPasses()) {
            is BrivoSDKApiState.Failed -> {
                promise.reject(result.brivoError.code.toString(), result.brivoError.message)
            }

            is BrivoSDKApiState.Success -> {
                val passesMap = result.data
                if (passesMap.isEmpty()) {
                    promise.resolve(null)
                } else {
                    promise.resolve(Gson().toJson(passesMap.values))
                }
            }
        }
    }

    override fun invalidate() {
        super.invalidate()
        job.cancel()
    }
}