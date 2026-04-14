# Brivo Sample React Native App

Sample React Native app demonstrating the Brivo Mobile SDK integration.

## Prerequisites

- Node.js >= 18
- Yarn
- Xcode (for iOS)
- Android Studio (for Android)
- CocoaPods

```bash
brew install node watchman
npm install -g yarn
```

## Configuration

Before running the app, you must provide your Brivo API credentials. Open `PassesScreen.js` and replace the placeholder values in the `BrivoSDK.init` call:

```javascript
BrivoSDK.init(JSON.stringify({
    "clientId": "<your-client-id>",
    "clientSecret": "<your-client-secret>",
    "useSDKStorage": true,
    "useEuRegion": false,
}))
```

- `clientId` and `clientSecret` are required. You can obtain these from the Brivo developer portal.
- `useEuRegion` should be set to `true` if your account is on the EU region, `false` for US.
- Without valid credentials, the SDK will fail to initialize and the app will show an error on launch.

Once the SDK is initialized, you can use the **ADD PASS** button to redeem a pass by entering your email and token. After redeeming, the app will display your access points which you can tap to unlock.

## Setup

```bash
cd brivo-sample
yarn install
```

### iOS

Install CocoaPods dependencies:

```bash
cd ios
pod install
cd ..
```

### Android

If you encounter the "SDK location not found" error, create or update `android/local.properties`:

```
sdk.dir=/Users/USERNAME/Library/Android/sdk
```

## Running the App

### iOS

Open two terminal windows:

**Terminal 1** - Start Metro bundler:
```bash
yarn start
# or
npx react-native start
```

**Terminal 2** - Build and run:
```bash
yarn ios
# or
npx react-native run-ios
```

#### Simulator Management

List available simulators:
```bash
xcrun simctl list devices available
```

Boot a specific simulator:
```bash
xcrun simctl boot "iPhone 17 Pro"
```

List currently booted simulators:
```bash
xcrun simctl list devices booted
```

Bring the Simulator app to the foreground:
```bash
open -a Simulator
```

Run on a specific simulator by name:
```bash
yarn ios --simulator="iPhone 16 Pro"
# or
npx react-native run-ios --simulator="iPhone 16 Pro"
```

Manually launch/relaunch the app on a booted simulator:
```bash
xcrun simctl launch booted com.brivo.sample.react
```

Terminate the app on the simulator:
```bash
xcrun simctl terminate booted com.brivo.sample.react
```

### Android

Open two terminal windows:

**Terminal 1** - Start Metro bundler:
```bash
yarn start
# or
npx react-native start
```

**Terminal 2** - Build and run:
```bash
yarn android
# or
npx react-native run-android
```

#### Emulator Management

List available emulators:
```bash
emulator -list-avds
```

Boot a specific emulator:
```bash
emulator -avd Pixel_7_API_34
```

List connected devices and running emulators:
```bash
adb devices
```

Run on a specific device/emulator by ID:
```bash
yarn android --deviceId="emulator-5554"
# or
npx react-native run-android --deviceId="emulator-5554"
```

Manually launch the app on a running emulator:
```bash
adb shell am start -n com.brivo/.MainActivity
```

Terminate the app on the emulator:
```bash
adb shell am force-stop com.brivo
```
