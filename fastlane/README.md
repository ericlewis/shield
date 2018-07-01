fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios production
```
fastlane ios production
```
Upload Shield & Metadata to App Store
### ios production_pro
```
fastlane ios production_pro
```
Upload Shield Pro & Metadata to App Store
### ios beta
```
fastlane ios beta
```
Upload Shield to TestFlight
### ios beta_pro
```
fastlane ios beta_pro
```
Upload Shield Pro to TestFlight
### ios tests
```
fastlane ios tests
```
Run Shield Unit & UI Tests
### ios tests_pro
```
fastlane ios tests_pro
```
Run Shield Pro Unit & UI Tests

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
