//
//  MasterViewController.swift
//  HomeControllerDemo
//
//  Created by Roderic Campbell on 3/15/18.
//  Copyright © 2018 Thumbworks. All rights reserved.
//

import UIKit
import HomeController

class ToggleCell: UITableViewCell {
    static let identifer = "SwitchCell"
    @IBOutlet weak var toggleSwitch: UISwitch!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var title: UILabel!
}

extension ToggleCell {
    func waitForUpdate() {
        loadingIndicator.isHidden = false
        toggleSwitch.isHidden = true
    }
    func update(value: UpdateResult) {
        loadingIndicator.isHidden = true
        
        switch value {
        case .value(let isOn):
            toggleSwitch.isOn = isOn.boolValue
            toggleSwitch.isHidden = false
        case .error(let error):
            print("error \(error)")
        }
        print("This new value is \(value)")
    }
}

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
    
    func update(cell: ToggleCell, with accessory: Accessory) {
        
        accessory.nameListener = { newName in
            cell.title.text = newName
        }
        cell.title.text = accessory.name()
    }
    
    func defaultCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.accessoryView = nil
        return cell
    }
    
    func switchCell(for indexPath: IndexPath) -> ToggleCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ToggleCell.identifer, for: indexPath) as! ToggleCell
        return cell
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let home = homeController.home

        switch indexPath.section {
        case 0:
            let therm =  home.thermostats[indexPath.row]
            let modeText = "mode " + therm.canSetThermostatMode().description
            let tempText = "temp " + therm.canSetTargetTemperature().description
            
            let cell = defaultCell(for: indexPath)
            cell.detailTextLabel!.text = modeText + " / " + tempText
            cell.textLabel?.text = therm.name()
            return cell
        case 1:
            
            let cell = switchCell(for: indexPath)
            let light = home.lights[indexPath.row]
            update(cell: cell, with: light)
            light.valueUpdate = { (value) in
                cell.update(value: value)
            }
            return cell
            
        case 2:
            let cell = switchCell(for: indexPath)
            let lock = home.locks[indexPath.row]
            lock.valueUpdate = { (value) in
                cell.update(value: value)
            }
            update(cell: cell, with: lock)
            return cell
            
        case 3:
            let cell = switchCell(for: indexPath)
            let toggle = home.toggles[indexPath.row]
            toggle.valueUpdate = { (value) in
                cell.update(value: value)
            }
            update(cell: cell, with: toggle)
            return cell
            
        default:
            let cell = defaultCell(for: indexPath)
            cell.textLabel?.text = "unknown"
            return cell
        }
        
    }
    @IBAction func switchChanged(sender: UISwitch) {
        
        print("sender changed \(sender.isOn)")
        if let cell = sender.superview?.superview as? ToggleCell {
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
                    lock.update(state: sender.isOn ? .unlocked : .locked)
                    print(lock, " turn it \(sender.isOn)")

                case 3:
                    let toggle = homeController.home.toggles[indexPath.row]
                    print(toggle, " turn it \(sender.isOn)")
                    let state: ToggleState = sender.isOn ? .on : .off
                    cell.waitForUpdate()
                    toggle.updateToggle(state) { (success) in
                        if !success {
                            print("update the toggle. It failed")
                            sender.isOn = state != .on
                        } else {
                            print("update the toggle. it worked")
                            cell.update(value: UpdateResult.value(sender.isOn as NSNumber))
                        }
                    }
                default:
                    break
                }
            }
        }
    }
}
