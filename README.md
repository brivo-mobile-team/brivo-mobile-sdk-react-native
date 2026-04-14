# README

## This is a sample app for react native which uses brivo mobile sdk, please reference the mobile sdk pages for further info:
- [https://github.com/brivo-mobile-team/brivo-mobile-sdk-ios]()
- [https://github.com/brivo-mobile-team/brivo-mobile-sdk-android]()

#
The current sample app uses the following mobile sdk's:
- iOS: [2.7.1](https://github.com/brivo-mobile-team/brivo-mobile-sdk-ios/releases/tag/2.7.1)
- Android: [2.7.0](https://github.com/brivo-mobile-team/brivo-mobile-sdk-android/releases/tag/2.6.2)
##

This README would normally document whatever steps are necessary to get your application up and running.
##

## Android Setup ~ 5 mins

### Install dependencies
```bash
brew install node
brew install watchman
brew install nvm
npm install -g yarn
```

### Configure project
```bash
cd BrivoSample
yarn install
```

Verify whether Gradle is installed by running the following command in your terminal:

```which gradle```

If the response indicates that gradle is not found, you can install it using Homebrew by executing:

```brew install gradle```

### Configure gradle
```bash
cd BrivoSample
cd android
gradle wrapper
```

If you encounter the "SDK location not found" error, you should define the ```sdk.dir``` property 
in the ```local.propertie```s file located in the android directory of your project. 
If the local.properties file does not exist, you may create it manually.

The entry should be as follows:
```
sdk.dir=/Users/USERNAME/Library/Android/sdk
```

### Configure Java **(!! Only if SDK man/java is not configured !!)**
```bash
cd BrivoSample
curl -s "https://get.sdkman.io" | bash
sdk install java 17.0.14-amzn
sdk use java 17.0.14-amzn
```

### Run development server
```bash
cd android
chmod +x gradlew
./gradlew clean
cd ..
yarn start
```

### Run sample app
**Normally you would just have to press "a"** after yarn start completes, if that doesn't work, do following :
```bash
# In a new terminal window
cd BrivoSample
yarn run android # Must have an android phone connected
```

# iOS
# Installing Dependencies

In order to build the mobile SDK React Native sample app, you need the following dependencies:
- Node
- Watchman
- React Native command line interface
- Xcode
- CocoaPods

```bash
brew install node
brew install watchman
brew install nvm
```

## iOS Setup

While you can use any editor of your choice to develop your app, you will need to install Xcode in order to set up the necessary tooling to build your React Native app for iOS.

### 1. CocoaPods Setup

~~CocoaPods is built with Ruby and it will be installable with the default Ruby available on macOS.
Using the default Ruby available on macOS will require you to use sudo when installing gems. (This is only an issue for the duration of the gem installation, though.)~~

It is recomanded to install ruby from brew, as mac os bundled is outdated

```bash
brew install ruby

sudo gem install -n /usr/local/bin cocoapods

nvm use 18

yarn install

cd ios

pod install

yarn start
```

### 2. Open iOS app on XCode
If yarn start doesn't open the app, or causes an "application quit unexpectedly", run yarn start, after that open the iOS project inside XCode and build/run the app from there.

**Note**: The path to the project should be: 
**\<path to SDK\>/BrivoMobileSDK/ReactNative/BrivoSample/ios/BrivoSample.xcworkspace**

## Troubleshooting:

### If, after running yarn start, on the metro terminal you get this:
*"TypeError: Cannot read property 'isBatchingLegacy' of undefined, js engine: hermes"*

**This should fix the issue:**
Open ***package.json*** and update ***"react": "~18.0.0"*** and ***"react-test-renderer": "^18.0.0"***

### If this error comes up:
*"typedef redefinition with different types ('uint8_t' (aka 'unsigned char') vs 'enum clockid_t')"*

**This should fix the issue:**
Go to `/Pods/RCT-Folly/Time.h` and remove line 52
or https://stackoverflow.com/a/74313290/19893505 

### If this error comes up:
*"Called object type 'facebook::flipper::SocketCertificateProvider' is not a function or function pointer"*

**This should fix the issue:**
Go to `/Pods/Flipper/FlipperTransportTypes.h` add: *#include "functional"* like this:
```cpp
#pragma once 
#include "functional" 
#include <string>
```

### If this error comes up:
*"Can't find the 'node' binary to build the React Native bundle. If you have a non-standard Node.js installation, select your project in Xcode, find 'Build Phases' - 'Bundle React Native code and images' and change NODE_BINARY to an absolute path to your node executable. You can find it by invoking 'which node' in the terminal."*

**This should fix the issue:**
On M1 Mac: cd /usr/local then mkdir bin (or just sudo mkdir /usr/local/bin).

```bash
ln -s $(which node) /usr/local/bin/node
```