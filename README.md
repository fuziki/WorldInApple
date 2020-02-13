# WorldInApple
![Platform](https://img.shields.io/badge/platform-%20iOS%20-lightgrey.svg)
![Swift](https://img.shields.io/badge/swift-green.svg)
![Xode](https://img.shields.io/badge/xcode-xcode11-green.svg)

Swift wrapper for vocoder World(https://github.com/mmorise/World)  
Support iOS & macOS  

# Required

* git
* carthage
* (optional) xcodegen

# Play iOS Example

```
git clone --recurse-submodules https://github.com/fuziki/WorldInApple
carthage update --platform iOS
open WorldInApple.xcodeproj
```

## (Optional)Make WorldInApple.xcodeproj

no need to generate. because .xcodeproj file is managed by git.

```
xcodegen generate
```

# Shift AVAudioPCMBuffer pitch and formant

make WorldInApple  
x_length = buffer.frameLength  

```swift
let worldInApple = WorldInApple(fs: 48000, frame_period: 5, x_length: 38400)
```

set pitch and formant  

```swift
worldInApple.set(pitch: Double(1.2))    //positive number
worldInApple.set(formant: Double(1.8))    //positive number
```

shit pitch and formant

```swift
let result = worldInApple.conv(buffer: buffer)
```

# Installation
## Carthage
```
github "fuziki/WorldInApple"
```

# Feature

- [x] support Carthage
- [ ] support macOS
- [] support cocopads
- [] support Swift Package Manager
