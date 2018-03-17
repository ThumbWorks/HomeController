//
//  MasterViewController.swift
//  HomeControllerDemo
//
//  Created by Roderic Campbell on 3/15/18.
//  Copyright © 2018 Thumbworks. All rights reserved.
//

import UIKit
import HomeController

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var objects = [Any]()
    let homeController: HomeController = {
        let home = HomeController()
        return home
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        homeController.finishedInitializing = {
            self.tableView.reloadData()
        }
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.leftBarButtonItem = editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

//    override func viewDidAppear(_ animated: Bool) {
////        homeController.homekitSetup()
////        print("home \(homeController.home.lights.count)")
//        tableView.reloadData()
//    }
    
    @objc
    func insertNewObject(_ sender: Any) {
        objects.insert(NSDate(), at: 0)
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
    }

    // MARK: - Segues
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let home = homeController.home
        
        switch section {
        case 0:
            return home.thermostats.count
        case 1:
            return home.lights.count
        case 2:
            return home.locks.count
        case 3:
            return home.toggles.count
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let home = homeController.home
        cell.detailTextLabel?.text = ""
        
        switch indexPath.section {
        case 0:
            let therm =  home.thermostats[indexPath.row]
            let modeText = "mode " + therm.canSetThermostatMode().description
            let tempText = "temp " + therm.canSetTargetTemperature().description

            cell.detailTextLabel!.text = modeText + " / " + tempText
            cell.textLabel?.text = therm.name()
        case 1:
            let light = home.lights[indexPath.row].description
            cell.textLabel?.text = light
        case 2:
            let lock = home.locks[indexPath.row]
            cell.textLabel?.text = lock.name()
        case 3:
            let toggle = home.toggles[indexPath.row]
            cell.textLabel?.text = toggle.name()
        
        default:
            cell.textLabel?.text = "unknown"
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Thermostats"
        case 1:
            return "Lights"
        case 2:
            return "Locks"
        case 3:
            return "Toggles"
        default:
            return "unknown"
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let home = homeController.home
        
        switch indexPath.section {
        case 0:
            let therm =  home.thermostats[indexPath.row]
            therm.setMode(to: .heat)

        case 1:
            let light = home.lights[indexPath.row].description
            print(light)
        case 2:
            let lock = home.locks[indexPath.row]
            print(lock)
        default:
            break
        }

    }
}

