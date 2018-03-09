//
//  HomeObjects.swift
//  MyHouse
//
//  Created by Roderic Campbell on 6/23/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import HomeKit

public class Home {
    public var thermostats = [Thermostat]()
    public var locks = [DoorLock]()
    public var lights = [Light]()
}

enum LockState {
    case Locked
    case Unlocked
    case Jammed
    case Unknown
}

enum LightState {
    case On
    case Off
    case Unknown
}

public class DoorLock: NSObject {
    
    let accessory: HMAccessory
    let readLockCharacteristic: HMCharacteristic
    let setLockCharacteristic: HMCharacteristic
    init(lock: HMAccessory, readLockedCharacteristic: HMCharacteristic, setLockedCharacteristic: HMCharacteristic) {
        accessory = lock
        readLockCharacteristic = readLockedCharacteristic
        setLockCharacteristic = setLockedCharacteristic
        
    }
    
    func enableNotifications() {
        readLockCharacteristic.enableNotification(true) { (error) in
            if let error = error {
                print("FAIL: There was an error with enabling notifications for read lock changes \(error.localizedDescription)")
            } else {
                print("SUCCESS: read lock notification set up properly")
            }
        }
        
        setLockCharacteristic.enableNotification(true) { (error) in
            if let error = error {
                print("FAIL: There was an error with enabling notifications for set lock changes \(error.localizedDescription)")
            } else {
                print("SUCCESS: set lock notification set up properly")
            }
        }
    }
    
    func isLocked(lockCheckHandler: @escaping (LockState) -> ()) {
        // read the lock state
        readLockCharacteristic.readValue(completionHandler: { (error) in
            if let error = error {
                print("There was an error reading the value of the charactersitic \(error.localizedDescription)")
            } else {
                print("successfully read the lock value \(String(describing: self.readLockCharacteristic.value))")
                
                guard let state = self.readLockCharacteristic.value as? Int else {
                    print("unclear what we got for lock value")
                    return
                }
                switch state {
                case HMCharacteristicValueLockMechanismState.jammed.rawValue:
                    lockCheckHandler(LockState.Jammed)
                case HMCharacteristicValueLockMechanismState.secured.rawValue:
                    lockCheckHandler(LockState.Locked)
                case HMCharacteristicValueLockMechanismState.unknown.rawValue:
                    lockCheckHandler(LockState.Unknown)
                case HMCharacteristicValueLockMechanismState.unsecured.rawValue:
                    lockCheckHandler(LockState.Unlocked)
                default:
                    print("unknown state for the Lock characteristic")
                }
            }
            self.enableNotifications()
        })
    }
    
    func unlockDoor() {
        setLockCharacteristic.writeValue(0, completionHandler: { (error) in
            if let error = error {
                print("error locking the door \(error)")
            } else {
                print("The door is now unlocked")
            }
        })
    }
    
    func lockDoor() {
        setLockCharacteristic.writeValue(1, completionHandler: { (error) in
            if let error = error {
                print("error unlocking door \(error)")
            } else {
                print("The door is now locked")
            }
        })
    }
}

public class Thermostat: NSObject {
    let accessory: HMAccessory
    let currentTempCharacteristic: HMCharacteristic
    init(thermostat: HMAccessory, currentTemp: HMCharacteristic) {
        accessory = thermostat
        currentTempCharacteristic = currentTemp
    }
    
    func enableNotifications() {
        if !currentTempCharacteristic.isNotificationEnabled {
            // Set up notifications for changes in current temperature
            currentTempCharacteristic.enableNotification(true) { (error) in
                if let error = error {
                    print("FAIL: There was an error with enabling notifications for temperature changes \(error.localizedDescription)")
                } else {
                    print("SUCCESS: current temperature notification set up properly")
                }
            }
        }
    }
    
    public func temperature() -> NSNumber {
        if let temperature =  self.currentTempCharacteristic.value as? NSNumber {
            return temperature
        }
        return 0
    }
    
    func currentTemperature(fetchedTemperatureHandler: @escaping (Float) -> ()) {
        currentTempCharacteristic.readValue(completionHandler: { (error) in
            if let error = error {
                print("There was an error reading the temperature value \(error.localizedDescription)")
            } else {
                print("successfully read the temperature value \(String(describing: self.currentTempCharacteristic.value))")
                if let temperature =  self.currentTempCharacteristic.value as? NSNumber {
                    fetchedTemperatureHandler(temperature.celsiusToFarenheit())
                }
            }
            self.enableNotifications()
        })
    }
}

extension NSNumber {
    func celsiusToFarenheit() -> Float {
        return self.floatValue * 1.8 + 32
    }
}

public class Light: NSObject {
    let characteristic: HMCharacteristic
    
    init(lightCharacteristic: HMCharacteristic) {
        characteristic = lightCharacteristic
    }
    
    func enableNotifications() {
        if !characteristic.isNotificationEnabled {
            characteristic.enableNotification(true) { (error) in
                if let error = error {
                    print("FAIL: There was an error with enabling notifications for light changes \(error.localizedDescription)")
                } else {
                    print("SUCCESS: current light notification set up properly")
                }
            }
        }
    }
    
    func turnOnLight(lightHandler: @escaping (Bool) -> ()) {
        characteristic.writeValue(1) { (error) in
            if let error = error {
                print("error \(error)")
                lightHandler(false)
            } else {
                lightHandler(true)
            }
        }
    }
    func turnOffLight(lightHandler: @escaping (Bool) -> ()) {
        characteristic.writeValue(0) { (error) in
            if let error = error {
                print("error \(error)")
                lightHandler(false)
            } else {
                lightHandler(true)
            }
        }
    }
    
    func isOn(lightCheckHandler: @escaping (LightState) -> ())  {
        characteristic.readValue(completionHandler: { (error) in
            if let error = error {
                print("There was an error reading the light value \(error.localizedDescription)")
                lightCheckHandler(.Unknown)
            } else {
                print("successfully read the light value \(String(describing: self.characteristic.value))")
                if let isOn = self.characteristic.value as? Bool {
                    print("inside the light block \(isOn)")
                    lightCheckHandler(isOn ? .On : .Off)
                } else {
                    lightCheckHandler(.Unknown)
                }
            }
        })
    }
}

