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
        else if characteristic == light?.characteristic {
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
    
    let homeManager = HMHomeManager()
    let homeManagerDelegate = HomeManagerDelegate()
    
    // closures
    var temperatureUpdate: ((Float) -> Void)?
    var lockUpdate: ((LockState) -> Void)?
    var lightUpdate: ((LightState) -> Void)?
    
    // Setup goes through all available devices to determine services and characteristics then stores references
    // in this HomeController instance
    public func homekitSetup() {
        homeManager.delegate = homeManagerDelegate
        
        if homeManager.homes.count == 0 {
            print("there are no homes")
            homeManager.addHome(withName: "arbutus", completionHandler: { (home, error) in
                guard let home = home else {
                    print("Error adding a home")
                    return
                }
                print("the home is \(home.name) error is \(String(describing: error))")
                if error == nil {
                    home.addRoom(withName: "Main Room", completionHandler: { (room, error) in
                        if let error = error {
                            print("Error creating room \(error)")
                        }
                    })
                }
            })
        } else {
            print(" found some homes \(homeManager.homes)")
            if let homeObject = homeManager.primaryHome {
                print("the accessories are \(homeObject.accessories)")
                for accessory in homeObject.accessories {
                    print(" services for \(accessory.name) \(accessory.category.categoryType). Is it the same as \(HMServiceTypeThermostat)")
                    
                    if accessory.category.categoryType == HMServiceTypeThermostat {
                        print("Hey this is a thermostat accessory")
                    }
                    
                    for service in accessory.services {
                        print("  service name: \(service.name) type: \(service.serviceType) uniqueID: \(service.uniqueIdentifier)")
                        if service.serviceType == HMServiceTypeThermostat {
                            print("Hey this is a thermostat service \(HMServiceTypeThermostat)")
                        }
                    }
                    print("\n\n")
                    for service in accessory.services {
                        // blindly set all accessory delegates to self, we can filter when we get the notifications
                        accessory.delegate = self
                        
                        if service.serviceType == HMServiceTypeThermostat {
                            print("Hey this is a thermostat service \(HMServiceTypeThermostat)")
                        }
                        
                        print("  this service \(service.name) has characteristics")
                        for characteristic in service.characteristics {
                            print("   characteristic \(characteristic.localizedDescription)")//\(characteristic.properties) ")
                            
                            if service.name == "Patio Light" && characteristic.localizedDescription == "Power State" {
                                home.lights.append(Light(lightCharacteristic: characteristic))
                            }
                            if characteristic.localizedDescription == "Current Temperature" {
                                print("      Current temperature type is \(characteristic.characteristicType)")
                                home.thermostats.append(Thermostat(thermostat: accessory, currentTemp: characteristic))
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
    }
}

extension HomeController {
    func toggleLight(completion: @escaping (LightState) -> ()) {
        home.lights.first?.isOn(lightCheckHandler: { (lightState) in
            switch lightState {
            case .On:
                self.turnOffFirstLight()
            case .Off:
                self.turnOnFirstLight()
            case .Unknown:
                print("unknown light state")
            }
            completion(lightState)
        })
    }
    func turnOnFirstLight() {
        home.lights.first?.turnOnLight(lightHandler: { (success) in
            if let lightUpdate = self.lightUpdate {
                lightUpdate(.On)
            } else {
                print("Failed to turn on the light")
            }
        })
    }
    
    func turnOffFirstLight() {
        home.lights.first?.turnOffLight(lightHandler: { (success) in
            if let lightUpdate = self.lightUpdate {
                // If this fails, send back a YES because we want to keep the lights on
                lightUpdate(.Off)
            } else {
                print("failed to turn off the light")
            }
        })
    }
    
    func lockFirstDoor() {
        home.locks.first?.lockDoor()
    }
    
    func unlockFirstDoor() {
        home.locks.first?.unlockDoor()
    }
}

