# HomeController 

A controller for your home controlled by HomeKit based on objects which makes discovering and interacting with accessories much more feasible.


## Carthage
`HomeController` is available through Carthage. To install it, simply add the following line to your Cartfile:

```
github "Thumbworks/HomeController"
```


## Setup
As HomeController uses HomeKit, you must:

1. include an `NSHomeKitUsageDescription` string in your Info.plist 
1. enable HomeKit capabilities on your Xcode project


## Basics

1. "import HomeController"
1. Retain an instance of `HomeController` object.
1. call `setupHomeKit()` on this object
1. Access your home through this object's `Home` which contains arrays of the following types: `DoorLock`, `Light`, `Toggle`, `Thermostat`

## Documentation

Soulful documentation was created by [Jazzy](https://github.com/realm/jazzy) and can be found [here](https://thumbworks.github.io/HomeController/)

## Example usage

```swift
let someSwitch = homeController.toggles.first
someSwitch?.updateToggle(.on) { (success) in
    if !success {
        print("something went wrong, update UI accordingly")
    } else 
        print("Looks like it worked, also update UI accordingly")
    }
}
```


## There is a Demo App

Just build and run.