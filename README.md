# WorldInApple

![Platform](https://img.shields.io/badge/platform-%20iOS%20-lightgrey.svg)
![Swift](https://img.shields.io/badge/swift-green.svg)
![Xode](https://img.shields.io/badge/xcode-xcode12-green.svg)

**Swift wrapper for vocoder World (https://github.com/mmorise/World)**

# Features
 * Support Platform
   * [x] iOS (iOS11 or later)
   * [x] macOS (Catalina or later)
* Property
  * [x] Shift Pitch
  * [x] Shift Formant
  
# Required

* Xcode 12

# Projects
## WorldInApple
### WorldInApple Target

* swift wrapper for World

### WorldLib

* World library source code
* fix header path
  * Because SwiftPM does not support USER_HEADER_SEARCH_PATHS
  * refer to the patch file for details. (fix-world-header-path.patch)

## Examples
### Multiplatform (iOS)

* Example for iOS

```
clone https://github.com/fuziki/WorldInApple
cd WorldInApple
open WorldInApple.xcworkspace
```

# Usage
## Shift AVAudioPCMBuffer pitch and formant

```swift
let buffer: AVAudioPCMBuffer
x_length = buffer.frameLength  
```

make WorldInApple instance

```swift
let worldInApple = WorldInApple(fs: 48000, frame_period: 5, x_length: 38400)
```

set pitch and formant  

```swift
worldInApple.set(pitch: Double(1.2))    //positive number
worldInApple.set(formant: Double(1.8))    //positive number
```

shift pitch and formant

```swift
let result = worldInApple.conv(buffer: buffer)
```

# Installation
## SwiftPM
```
https://github.com/fuziki/WorldInApple
```

# Makefile

* install-worldlib
  * download World
  * copy files
  * apply patch file

* clean-worldlib
  * clean world
