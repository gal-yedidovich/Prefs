# Prefs - Safe Key-Value storage. 

Insapired after iOS's `UserDefaults` & Android's `SharedPreferences`, The `Prefs` class enables you to manage Key-Value pairs easily and securely using the encryption layer from `CryptoExtensions`, also comes with a caching logic for fast & non blocking read/writes operation in memory.

## Installation
Prefs is a *Swift Package*. 

Use the swift package manager to install SwiftExtensions on your project. [Apple Developer Guide](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)

##Usage
You can either use the `standard` instance, which is also using an obfuscated filename, or create your own instances for multiple files, like so:

```swift
let standardPrefs = Prefs.standard //the built-in standard instance 

//OR
let myPrefs = Prefs(file: .myFile1) //new instance using the Filename struct
```

Writing values: 
```swift	
extension PrefKey {
	static let name = PrefKey(value: "obfuscatedKey") //value should be obfuscated
}

let myPrefs.edit() //start editing
	.put(key: .name, "Bubu") //using the static constant '.name'
	.commit() //save your changes in memory & lcoal storage
```


Reading value:
```swift
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

> `Prefs.publisher` will fire events when the prefs instance has committed non-empty commits.
