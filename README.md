[![Build Status](https://travis-ci.com/thepracticaldev/DEV-ios.svg?branch=master)](https://travis-ci.com/thepracticaldev/DEV-ios)
[![GitHub License](http://img.shields.io/badge/License-GPL%20v3-blue.svg?style=flat)](https://github.com/thepracticaldev/DEV-ios/blob/master/LICENSE)
[![Language](https://img.shields.io/badge/Language-Swift_5-f48041.svg?style=flat)](https://developer.apple.com/swift)
[![Maintainability](https://api.codeclimate.com/v1/badges/b162322067740725ad02/maintainability)](https://codeclimate.com/github/thepracticaldev/DEV-ios/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/b162322067740725ad02/test_coverage)](https://codeclimate.com/github/thepracticaldev/DEV-ios/test_coverage)

# DEV iOS 💖

This is the repo for the [dev.to](https://dev.to) iOS app.

# Status:

Released first version, more info: https://twitter.com/bendhalpern/status/1061323718058786822

# Design ethos

We will grow to include more native code over time, but for now we are taking the approach of _native shell/web views_. This approach lost favor early in iOS days, but I believe it is a very valid approach these days. It is inspired by how Basecamp does things. Our tech stack is a bit different, but the ideas are the same. 

https://m.signalvnoise.com/basecamp-3-for-ios-hybrid-architecture-afc071589c25

https://signalvnoise.com/posts/3743-hybrid-sweet-spot-native-navigation-web-content

https://signalvnoise.com/posts/3766-hybrid-how-we-took-basecamp-multi-platform-with-a-tiny-team

https://www.youtube.com/watch?v=SWEts0rlezA

By leveraging `wkwebviews` as much as possible, I think we can make this all pretty awesome and sync up with our web dev work pretty smoothly. And where it makes sense, we can re-implement certain things fully native, or build entirely native features. Life's a journey, not a destination.

# Contributing
1. Fork and clone the project.
2. Install [Carthage](https://github.com/Carthage/Carthage). If you use Homebrew then you can install Carthage by running `brew install carthage`.
3. Now run `./carthage.sh update --no-use-binaries --platform iOS --cache-builds` in the project's root directory (see [Carthage bug for more details](https://github.com/Carthage/Carthage/blob/master/Documentation/Xcode12Workaround.md)).
4. Build and run the project in XCode.
5. To enforce code style we're using [SwiftLint](https://github.com/realm/SwiftLint) which is loosely based on [GitHub's Swift Style Guide](https://github.com/github/swift-style-guide). [CodeClimate](https://codeclimate.com) is enabled for this repository, so your pull request build will fail if there are linting errors!
  1. To install, `brew install swiftlint`.
  2. If you are using Xcode, add a new "Run Script Phase" (Xcode project > Build Phases > add New Run Script Phase):
  ```bash
  if which swiftlint >/dev/null; then
    swiftlint
  else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
  fi
  ```
   This will run on build and show linting errors in Xcode. If you are using a different IDE there are alternative install methods in the [SwiftLint](https://github.com/realm/SwiftLint) docs.
  3. Alternatively you can run `$ swiftlint` in the root directory.


Feedback and Pull Requests are welcome! As this is a new and constantly evolving project, please be sure to include unit tests with changes.

# Thanks for your help!!!
