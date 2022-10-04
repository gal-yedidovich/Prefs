# Prefs - Safe Key-Value storage. 

Insapired after iOS's `UserDefaults` & Android's `SharedPreferences`, The `Prefs` class enables you to store Key-Value pairs easily and securely using the encryption layer from `CryptoExtensions`, also comes with a caching logic for fast & non blocking read/writes operation in memory.

## Installation
Prefs is a *Swift Package*. 

Use the swift package manager to install Prefs on your project. [Apple Developer Guide](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)

## Usage
You can either use the `standard` instance, which is also using an obfuscated filename, or create your own instances for multiple files, like so:

```swift
let standardPrefs = Prefs.standard //the built-in standard instance 

//OR
let myPrefs = Prefs(suite: "My prefs suite") //new instance with a suite name
```

Writing & reading values: 
> Prefs support any type that conforms to the `Codable` protocol,
```swift
//Defining a key
extension Prefs.Key {
	static let name = Prefs.Key(value: "obfuscated_key") //value should be obfuscated
}

let myPrefs.edit() //start editing
	.put(key: .name, "Bubu") //using the static constant '.name'
	.commit() //save your changes in memory & lcoal storage

if let name = myPrefs.string(key: .name) {
	print("\(name), is the king")
}
``` 

Observing changes with `Combine` Framework
```swift
let cancelable1 = myPrefs.publisher
	.sink { prefs in print("prefs changed") } //prints "prefs changed" whenever we commit changes.


//Detecting changes on a key 
let cancelable2 = prefs.publisher
	.compactMap { $0.string(key: .name) }
	.removeDuplicates()
	.sink { print("name changed to: \($0)") }
```

> `Prefs.publisher` will fire events only when the prefs instance has committed non-empty commits.

## @PrefsValue property wrapper
A simple property wrapper for easy `Prefs` manipulation. Also, it allows to update SwiftUI views when wrapped value changes (both from view or directly the prefs)

```swift
let prefKey = Prefs.Key(value: "score_key")
@PrefsValue(prefKey) var score = 0 //reads value from prefs or uses default value instead
score = 100 // commits an update to the prefs on assignments
```

By default `@PrefsValue` connects to the `Prefs.standard` instance, but it can connect to any instance explictly

```swift
let myPrefs = Prefs(suite: "some suite")
@PrefsValue(prefKey, prefs: myPrefs) var score = 0
```

Example in a SwiftUI view
```swift
import SwiftUI

extension Prefs.Key {
	static let countKey = Prefs.Key(value: "count_key")
}

struct MyView: View {
	@PrefValue(.countKey) private var count = 0
	
	body: some View {
		VStack {
			Text("Count: \(count)")
			
			Button("increment pref value") {
				count += 1
			}
		}
	}
}
```
