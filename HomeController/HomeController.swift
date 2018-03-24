//
//  HomeController.swift
//  MyHouse
//
//  Created by Roderic Campbell on 5/23/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import HomeKit
extension HomeController: HMAccessoryDelegate {
    public func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
        print("an accessory updated")
        let lock = home.locks.first
        let light = home.lights.first
        let thermostat = home.thermostats.first
        if characteristic == lock?.setLockCharacteristic {
            print("the door lock changed")
            guard let closure = lockUpdate else {
                print("no lock closure defined")
                return
            }
            lock?.isLocked(lockCheckHandler: { (lockState) in
                closure(lockState)
            })
        }
        else if characteristic == light?.updateLightCharacteristic {
            guard let closure = lightUpdate else {
                print("no light closure defined")
                return
            }
            light?.isOn(lightCheckHandler: { (lightState) in
                closure(lightState)
            })
        }
        else if characteristic == thermostat?.currentTempCharacteristic {
            if let temperature = thermostat?.temperature(), let closure = temperatureUpdate {
                print("Thermostat changed \(temperature)")
                closure(temperature.celsiusToFarenheit())
            }
        }
        else {
            print("An untracked accessory changed state: Accessory: \(accessory). Service: \(service). Characteristic: \(characteristic), \(characteristic.localizedDescription)")
        }
    }
}

public class HomeController: NSObject {
    public var home = Home()
    
    public var finishedInitializing: (() ->())?
    
    let homeManager = HMHomeManager()
    let homeManagerDelegate = HomeManagerDelegate()
    
    // closures
    var temperatureUpdate: ((Float) -> Void)?
    var lockUpdate: ((LockState) -> Void)?
    var lightUpdate: ((ToggleState) -> Void)?
    
    override public init() {
        homeManager.delegate = homeManagerDelegate
        super.init()
        homeManagerDelegate.doneUpdatingHomes = {
            print("done updating homes")
            self.homekitSetup()
            self.finishedInitializing?()
        }
    }
    
    // Setup goes through all available devices to determine services and characteristics then stores references
    // in this HomeController instance
    public func homekitSetup() {
        
        guard homeManager.homes.count > 0 else {
            print("there are no homes")
            return
        }
        print(" found some homes \(homeManager.homes)")
        guard let homeObject = homeManager.primaryHome else {
            print("there is no primary home")
            return
        }
        
        
        print("the accessories are")
        _ = homeObject.accessories.map({print("\($0)")})
        for accessory in homeObject.accessories {
            print("\nIterate through services for accessory: \(accessory.name) \(accessory.category.categoryType). Model: \(accessory.model) manufacturer \(accessory.manufacturer)")
            for service in accessory.services {
                // blindly set all accessory delegates to self, we can filter when we get the notifications
                accessory.delegate = self
                
                print("   service name: \(service.name) \(service.localizedDescription)")//" type: \(service.serviceType) uniqueID: \(service.uniqueIdentifier) ")
                
                if service.serviceType == HMServiceTypeSwitch {
                    home.toggles.append(Toggle(toggle: accessory))
                }
                if service.serviceType == HMServiceTypeLightbulb {
                    let light = Light(light: accessory)
                    light.enableNotifications()
                    home.lights.append(light)
                }
                
                print("\n  this service <<<\(service.name)>>> has characteristics")
                for characteristic in service.characteristics {
                    if characteristic.localizedDescription == "Target Temperature" {
                        print("This can set the temp. characteristic is \(characteristic)")
                    }
                    print("      characteristic \(characteristic.localizedDescription)")//\(characteristic.properties) ")
                    

                    if characteristic.localizedDescription == "Current Temperature" {
                        print("       ✅Thermostat Current temperature type is \(characteristic.characteristicType)")
                        let thermostat = Thermostat(thermostat: accessory)
                        thermostat.currentTemperature(fetchedTemperatureHandler: { (temp) in
                            print("       ✅Thermostat says the temperature is \(temp)")
                        })
                        print("       ✅append thermostat")
                        home.thermostats.append(thermostat)
                    }
                    if characteristic.localizedDescription == "Lock Mechanism Current State" {
                        print("      Current lock state mechanism type is \(characteristic.characteristicType)")
                        
                        // We now know that this is a lock, it has a characteristicType for modifying, let's find it
                        let lockCharArray = service.characteristics.filter({ (filterCharactersitic) -> Bool in
                            if (filterCharactersitic.localizedDescription == "Lock Mechanism Target State") {
                                return true
                            }
                            return false
                        })
                        
                        guard let lockChar = lockCharArray.first else {
                            print("We did not get a set lock characteristic")
                            return
                        }
                        print("      Lock mechanism type is \(lockChar.characteristicType)")
                        let newLock = DoorLock(lock: accessory, readLockedCharacteristic: characteristic, setLockedCharacteristic: lockChar)
                        home.locks.append(newLock)
                        newLock.enableNotifications()
                    }
                }
            }
        }
        
    }
    
}
