# SpeechRecognizerButton

[![Twitter](https://img.shields.io/badge/contact-@alexruperez-0FABFF.svg?style=flat)](http://twitter.com/alexruperez)
[![Version](https://img.shields.io/cocoapods/v/SpeechRecognizerButton.svg?style=flat)](http://cocoapods.org/pods/SpeechRecognizerButton)
[![License](https://img.shields.io/cocoapods/l/SpeechRecognizerButton.svg?style=flat)](http://cocoapods.org/pods/SpeechRecognizerButton)
[![Platform](https://img.shields.io/cocoapods/p/SpeechRecognizerButton.svg?style=flat)](http://cocoapods.org/pods/SpeechRecognizerButton)
[![Swift](https://img.shields.io/badge/Swift-4-orange.svg?style=flat)](https://swift.org)
[![Build Status](https://travis-ci.org/alexruperez/SpeechRecognizerButton.svg?branch=master)](https://travis-ci.org/alexruperez/SpeechRecognizerButton)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift Package Manager Compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-4BC51D.svg?style=flat)](https://github.com/apple/swift-package-manager)

UIButton subclass with push to talk recording, speech recognition and Siri-style waveform view.

![SpeechRecognizerButton](https://github.com/alexruperez/SpeechRecognizerButton/raw/master/SpeechRecognizerButton.gif)

## 📲 Installation

SpeechRecognizerButton is available through [CocoaPods](http://cocoapods.org). To install it,
simply add the following line to your Podfile:

```ruby
pod 'SpeechRecognizerButton'
```

#### Or you can install it with [Carthage](https://github.com/Carthage/Carthage):

```ogdl
github "alexruperez/SpeechRecognizerButton"
```

#### Or install it with [Swift Package Manager](https://swift.org/package-manager/):

```swift
dependencies: [
    .package(url: "https://github.com/alexruperez/SpeechRecognizerButton.git")
]
```

## 🐒 Usage

### Configuration:

Add `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` keys to your `Info.plist` file containing a description of how your app will use the voice recording and speech recognition.

### Handling authorization:

#### Automatically opening Settings when denying permission:

```swift
button.authorizationErrorHandling = .openSettings(completion: ...)
```

#### Custom handling:

```swift
button.authorizationErrorHandling = .custom(handler: { error in
  // TODO: Your code here!
})
```

### Handling results:

```swift
button.resultHandler = { recordURL, speechRecognitionResult in
  // TODO: Your code here!
}
```

### Handling errors:

```swift
button.errorHandler = { error in
  // TODO: Your code here!
}
```

### Assigning waveform view:

Just set `weak var waveformView: SFWaveformView?` property or use the Interface Builder outlet.

### Assigning activity indicator view:

Just set `weak var activityIndicatorView: UIActivityIndicatorView?` property or use the Interface Builder outlet.

### Customizing SFButton configuration:

Just set the following properties by code or use the Interface Builder inspectables.

```swift
button.audioSession...
button.recordURL = ...
button.audioFormatSettings = [AV...Key: ...]
button.maxDuration = ...
button.locale = Locale....
button.taskHint = SFSpeechRecognitionTaskHint....
button.queue = OperationQueue....
button.contextualStrings = ["..."]
button.interactionIdentifier = "..."
button.animationDuration = ...
button.shouldVibrate = ...
button.shouldSound = ...
button.pushToTalk = ...
button.speechRecognition = ...
button.cancelOnDrag = ...
button.shouldHideWaveform = ...
button.cornerRadius = ...
button.borderColor = ...
button.borderWidth = ...
button.selectedColor = ...
button.highlightedColor = ...
button.disabledColor = ...
button.highlightedAlpha = ...
```

### Customizing SFWaveformView configuration:

Just set the following properties by code or use the Interface Builder inspectables.

```swift
waveformView.waveColor = ...
waveformView.numberOfWaves = ...
waveformView.primaryWaveLineWidth = ...
waveformView.secondaryWaveLineWidth = ...
waveformView.idleAmplitude = ...
waveformView.frequency = ...
waveformView.density = ...
waveformView.phaseShift = ...
waveformView.amplitude = ...
```

## ❤️ Etc.

* [SFWaveformView](https://github.com/alexruperez/SpeechRecognizerButton/blob/master/SpeechRecognizerButton/SFWaveformView.swift#L6) based on [jyunderwood](https://github.com/jyunderwood)/[WaveformView-iOS](https://github.com/jyunderwood/WaveformView-iOS), thanks!
* Contributions are very welcome.
* Attribution is appreciated (let's spread the word!), but not mandatory.

## 👨‍💻 Authors

[alexruperez](https://github.com/alexruperez), contact@alexruperez.com

## 👮‍♂️ License

SpeechRecognizerButton is available under the MIT license. See the LICENSE file for more info.
