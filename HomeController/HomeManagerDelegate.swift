//
//  HomeManagerDelegate.swift
//  MyHouse
//
//  Created by Roderic Campbell on 5/18/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import HomeKit

class HomeManagerDelegate: NSObject, HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        print("updated homes")
    }
    func homeManagerDidUpdatePrimaryHome(_ manager: HMHomeManager) {
        print("updated primary")
    }
    func homeManager(_ manager: HMHomeManager, didAdd home: HMHome) {
        print("did add a home \(home)")
    }
    func homeManager(_ manager: HMHomeManager, didRemove home: HMHome) {
        print("did remove \(home)")
    }
}

