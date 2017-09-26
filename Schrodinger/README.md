# Schrodinger

An extremely simple promise library.

## Usage

Add a Package.swift dependency:

`.Package(url: "https://github.com/OpenKitten/Schrodinger.git", majorVersion: 1)`

Run code asynchronously and await their results.
Supports error throwing.

```swift
let promisedResult = async {
	// Run your heavy code
	throw An.error
	
 	return successfulResults
}

try promise.await()
```

And set custom timeouts.

```swift
// times out after a minute
let promise = async(timingOut: .seconds(60)) {
	...
}
```