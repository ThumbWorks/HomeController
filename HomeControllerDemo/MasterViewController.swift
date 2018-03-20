//
//  MasterViewController.swift
//  HomeControllerDemo
//
//  Created by Roderic Campbell on 3/15/18.
//  Copyright © 2018 Thumbworks. All rights reserved.
//

import UIKit
import HomeController

class MasterViewController: UIViewController {

    var detailViewController: DetailViewController? = nil
    var objects = [Any]()
    let homeController: HomeController = {
        let home = HomeController()
        return home
    }()

    @IBOutlet weak var tableView: UITableView!
    
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
}

extension MasterViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
extension MasterViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    func update(cell: UITableViewCell, with accessory: Accessory) {
        cell.textLabel?.text = accessory.description
        cell.accessoryView = cellSwitch()
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.accessoryView = nil
        cell.detailTextLabel?.text = ""
        let home = homeController.home

        switch indexPath.section {
        case 0:
            let therm =  home.thermostats[indexPath.row]
            let modeText = "mode " + therm.canSetThermostatMode().description
            let tempText = "temp " + therm.canSetTargetTemperature().description
            
            cell.detailTextLabel!.text = modeText + " / " + tempText
            cell.textLabel?.text = therm.name()
        case 1:
            update(cell: cell, with: home.lights[indexPath.row])
            
        case 2:
            update(cell: cell, with: home.locks[indexPath.row])
            
        case 3:
            let toggle = home.toggles[indexPath.row]
            cell.textLabel?.text = toggle.name()
            cell.accessoryView = cellSwitch()
            
        default:
            cell.textLabel?.text = "unknown"
        }
        
        return cell
    }
    
    @objc private func switchChanged(sender: UISwitch) {
        print("sender changed \(sender.isOn)")
        if let cell = sender.superview as? UITableViewCell {
            if let indexPath = tableView.indexPath(for: cell) {
                switch indexPath.section {
                case 0:
                    break
                    
                case 1:
                    let light = homeController.home.lights[indexPath.row]
                    print(light, " turn it \(sender.isOn)")
                    
                    let state: ToggleState = sender.isOn ? .on : .off
                    light.update(lightState: state, completion: { (success) in
                        if !success {
                            sender.isOn = !sender.isOn
                        }
                    })
                    
                case 2:
                    let lock = homeController.home.locks[indexPath.row]
                    print(lock, " turn it \(sender.isOn)")

                case 3:
                    let toggle = homeController.home.toggles[indexPath.row]
                    print(toggle, " turn it \(sender.isOn)")
                    let state: ToggleState = sender.isOn ? .on : .off
                    
                    toggle.updateToggle(state) { (success) in
                        if !success {
                            sender.isOn = state != .on
                        }
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func cellSwitch() -> UISwitch {
        let switchView = UISwitch()
        switchView.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged)
        return switchView
    }
}
