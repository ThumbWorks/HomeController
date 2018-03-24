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
    public var toggles = [Toggle]()
}

public enum LockState {
    case locked
    case unlocked
    case jammed
    case unknown
}

public enum ToggleState {
    case on
    case off
    case unknown
}

public class DoorLock: Accessory {
    
    let readLockCharacteristic: HMCharacteristic
    let setLockCharacteristic: HMCharacteristic
    init(lock: HMAccessory, readLockedCharacteristic: HMCharacteristic, setLockedCharacteristic: HMCharacteristic) {
        readLockCharacteristic = readLockedCharacteristic
        setLockCharacteristic = setLockedCharacteristic
        super.init(accessory: lock)
    }
    
    func enableNotifications() {
        readLockCharacteristic.enableNotification(true) { (error) in
            if let error = error {
                print("FAIL: There was an error with enabling notifications for read lock changes \(error.localizedDescription)")
                self.valueUpdate?(UpdateResult.error(error))
            } else {
                self.readLockCharacteristic.readValue(completionHandler: { (error) in
                    print("we got self.readLockCharacteristic.value \(self.readLockCharacteristic.value)")
                    if let error = error {
                        self.valueUpdate?(UpdateResult.error(error))
                    } else if let number = self.readLockCharacteristic.value as? NSNumber {
                        self.valueUpdate?(UpdateResult.value(number))
                    }
                })
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
                    lockCheckHandler(.jammed)
                case HMCharacteristicValueLockMechanismState.secured.rawValue:
                    lockCheckHandler(.locked)
                case HMCharacteristicValueLockMechanismState.unknown.rawValue:
                    lockCheckHandler(.unknown)
                case HMCharacteristicValueLockMechanismState.unsecured.rawValue:
                    lockCheckHandler(.unlocked)
                default:
                    print("unknown state for the Lock characteristic")
                }
            }
            self.enableNotifications()
        })
    }
    
    public func update(state: LockState) {
        var newValue: NSNumber?
        switch state {
        case .locked:
            newValue = 1
        case .unlocked:
            newValue = 0
        case .jammed, .unknown:
            break
        }
        guard let value = newValue else {return}
        setLockCharacteristic.writeValue(value, completionHandler: { (error) in
            if let error = error {
                print("error setting door lock to \(state). Error: \(error)")
            } else {
                print("The door is now in the state: \(state)")
            }
        })
    }
}

public class Accessory: NSObject {
    let accessory: HMAccessory
    
    var value: NSNumber = 0
    init(accessory: HMAccessory) {
        self.accessory = accessory
    }

    public var valueUpdate: ((UpdateResult) -> ())?

    public var nameListener: ((String) -> ())?
    lazy var nameCharacteristic: HMCharacteristic? = {
        let characteristic = accessory.characteristic(with: "Name")
        characteristic?.readValue(completionHandler: { (error) in
            if let error = error {
                print("error fetching name \(error)")
            } else {
                print("we got the name \(characteristic?.value)")
            }
        })
        return characteristic
    }()
    
    public func name() -> String {
        guard let newName = self.nameCharacteristic?.service?.name else {
            return "it isn't the service"
        }
        return newName
    }
}

public enum ThermostatMode: Int {
    case off
    case heat
    case cool
    case fan
}

public class Toggle: Accessory {
    lazy var updateToggleCharacteristic: HMCharacteristic? = {
        return accessory.characteristic(with: "Power State")
    }()
    
    init(toggle: HMAccessory) {
        super.init(accessory: toggle)
        
        updateToggleCharacteristic?.readValue { (error) in
            if let error = error {
                self.valueUpdate?(UpdateResult.error(error))
            }
            else if let value = self.updateToggleCharacteristic?.value as? NSNumber {
                self.valueUpdate?(UpdateResult.value(value))
            }
        }
    }
    
    
    public func updateToggle(_ state: ToggleState, completion: @escaping (Bool) -> ()) {
        let isOn = state == .on
        updateToggleCharacteristic?.writeValue(isOn) { (error) in
            if let error = error {
                completion(false)
                print("This didn't work \(error)")
            } else {
                completion(true)
                print("Looks like setting the toggle to \(self.updateToggleCharacteristic?.value!) worked")
            }
        }
    }
}

extension HMAccessory {
    func characteristic(with string: String) -> HMCharacteristic? {
        return services.filter { (service) -> Bool in
            service.characteristics.filter({ (characteristic) -> Bool in
                return characteristic.localizedDescription == string
            }).count > 0
            }.first?.characteristics.filter({ (characteristic) -> Bool in
                return characteristic.localizedDescription == string
            }).first
    }
}

public class Thermostat: Accessory {
    lazy var currentTempCharacteristic: HMCharacteristic? = {
        return accessory.characteristic(with: "Current Temperature")
    }()
    
    lazy var currentModeCharacteristic: HMCharacteristic? = {
        return accessory.characteristic(with: "Target Heating Cooling State")
    }()
    
    
    init(thermostat: HMAccessory) {
        super.init(accessory: thermostat)
    }
    
    public func setMode(to mode: ThermostatMode) {
        guard let characteristic = currentModeCharacteristic else {
            print("Can not set the mode for an object without the supported characteristic")
            return
        }
        characteristic.writeValue(mode.rawValue) { (error) in
            if let error = error {
                print("This didn't work \(error)")
            } else {
                print("Looks like setting the mode for the thermostat worked")
            }
        }
        print("the mode setting characteristics should be 1 or 0 \(characteristic)")
    }
    
    public func canSetThermostatMode() -> Bool {
        return accessory.services.filter { (service) -> Bool in
            service.characteristics.filter({ (characteristic) -> Bool in
                return characteristic.localizedDescription == "Target Heating Cooling State"
            }).count > 0
            }.count > 0
    }
    
    public func canSetTargetTemperature() -> Bool {
        return accessory.services.filter { (service) -> Bool in
            service.characteristics.filter({ (characteristic) -> Bool in
                return characteristic.localizedDescription == "Target Temperature"
            }).count > 0
            }.count > 0
    }
    
    func enableNotifications() {
        print("THERMOSTAT attempt to enable notificaitons on this")
        guard let characteristic = currentTempCharacteristic else {
            print("we can't do notifications if there is no mode characteristic")
            return
        }
        if !characteristic.isNotificationEnabled {
            // Set up notifications for changes in current temperature
            characteristic.enableNotification(true) { (error) in
                if let error = error {
                    print("FAIL: THERMOSTAT There was an error with enabling notifications for temperature changes \(error.localizedDescription)")
                } else {
                    print("SUCCESS: THERMOSTAT current temperature notification set up properly")
                }
            }
        } else {
            print("THERMOSTAT notifications not enabled on this characteristic")
        }
    }
    
    public func temperature() -> NSNumber {
        if let temperature =  self.currentTempCharacteristic?.value as? NSNumber {
            return temperature
        }
        return 0
    }
    
    func currentTemperature(fetchedTemperatureHandler: @escaping (Float) -> ()) {
        currentTempCharacteristic?.readValue(completionHandler: { (error) in
            if let error = error {
                print("THERMOSTAT There was an error reading the temperature value \(error.localizedDescription)")
            } else {
                print("THERMOSTAT successfully read the temperature value \(String(describing: self.currentTempCharacteristic?.value))")
                if let temperature =  self.currentTempCharacteristic?.value as? NSNumber {
                    print("THERMOSTAT fetrched temperature handler")
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

public enum UpdateResult {
    case value(NSNumber)
    case error(Error)
}

public class Light: Accessory {
    
    lazy var updateLightCharacteristic: HMCharacteristic? = {
        return accessory.characteristic(with: "Power State")
    }()
    
    init(light: HMAccessory) {
        super.init(accessory: light)
        enableNotifications()
    }
    
    func enableNotifications() {
        
        guard let characteristic = updateLightCharacteristic else {
            print("no characteristic found for this light")
            return
        }
        characteristic.readValue { (error) in
            if let error = error {
                self.valueUpdate?(UpdateResult.error(error))
            }
            else if let value = characteristic.value as? NSNumber {
                self.valueUpdate?(UpdateResult.value(value))
            }
        }
        if !characteristic.isNotificationEnabled {
            characteristic.enableNotification(true) { (error) in
                if let error = error {
                    print("FAIL: There was an error with enabling notifications for light changes \(error.localizedDescription)")
                } else {
                    print("SUCCESS: current light notification set up properly")
                }
            }
        } else {
            print("notifications are not available for this light")
        }
    }
    
    public func update(lightState: ToggleState, completion: @escaping (Bool) -> ()) {
        
        switch lightState {
            
        case .on, .off:
            updateLightCharacteristic?.writeValue(lightState == .on) { (error) in
                if let error = error {
                    print("error \(error)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
            
        case .unknown:
            break
        }
        
    }
    
    func isOn(lightCheckHandler: @escaping (ToggleState) -> ())  {
        updateLightCharacteristic?.readValue(completionHandler: { (error) in
            if let error = error {
                print("There was an error reading the light value \(error.localizedDescription)")
                lightCheckHandler(.unknown)
            } else {
                print("successfully read the light value \(String(describing: self.updateLightCharacteristic?.value))")
                if let isOn = self.updateLightCharacteristic?.value as? Bool {
                    print("inside the light block \(isOn)")
                    lightCheckHandler(isOn ? .on : .off)
                } else {
                    lightCheckHandler(.unknown)
                }
            }
        })
    }
}

