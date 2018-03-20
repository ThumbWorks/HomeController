# HomeController 

A controller for your home controlled by HomeKit


## Carthage
Use Carthage to install HomeController

## Setup
As HomeController uses HomeKit, you must:

1. include an `NSHomeKitUsageDescription` string in your Info.plist 
2. enable HomeKit capabilities on your Xcode project


## Basics

1. Retain an instance of `HomeController`
2. Access your home through this object's `Home` which contains arrays of the following types `DoorLock`, `Light`, `Toggle`, `Thermostat`


## There is a Demo App

You'll need to 
1. Set the home kit capability
2. Set your Info.plist privacy setting for `NSHomeKitUsageDescription`
