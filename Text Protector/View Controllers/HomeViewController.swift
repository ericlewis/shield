//
//  HomeViewController.swift
//  Text Protector
//
//  Created by Eric Lewis on 6/24/18.
//  Copyright © 2018 Eric Lewis Innovations, LLC. All rights reserved.
//

import UIKit
import SwiftyStoreKit
import KeychainSwift
import AVKit
import AVFoundation

class HomeViewController: UITableViewController {
    
    @IBOutlet weak var startFilterCell: UITableViewCell!
    @IBOutlet weak var filterStatusCell: UITableViewCell!
    @IBOutlet weak var checkForUpdates: UITableViewCell!
    @IBOutlet weak var smartFilterCell: UITableViewCell!
    @IBOutlet weak var whitelistCell: UITableViewCell!
    @IBOutlet weak var blacklistCell: UITableViewCell!
    @IBOutlet weak var reportCell: UITableViewCell!
    @IBOutlet weak var testCell: UITableViewCell!
    @IBOutlet weak var aboutCell: UITableViewCell!
    @IBOutlet weak var updateCell: UITableViewCell!
    
    let activity = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    let smartFilterSwitch = UISwitch()
    
    fileprivate let coreDataManager = CoreDataManager(modelName: "Lists")
    fileprivate let downloader = Downloader()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if pro {
            title = "Shield Pro"
        }
        
        smartFilterCell.imageView?.image = UIImage(named: "smartFilter")
        whitelistCell.imageView?.image = UIImage(named: "whitelist")
        blacklistCell.imageView?.image = UIImage(named: "blocklist")
        reportCell.imageView?.image = UIImage(named: "report")
        testCell.imageView?.image = UIImage(named: "test")
        aboutCell.imageView?.image = UIImage(named: "about")
        updateCell.imageView?.image = UIImage(named: "update")

        smartFilterSwitch.addTarget(self, action: #selector(smartSwitchValueChanged), for: .valueChanged)
        smartFilterSwitch.onTintColor = .orange
        activity.color = .orange
        
        smartFilterCell.accessoryView = smartFilterSwitch
        
        // Download model + SMS messages
        downloader.managedObjectContext = coreDataManager.backgroundManagedObjectContext
        downloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if UserDefaults.standard.string(forKey: "firstRun") == nil {
            UserDefaults.standard.set("ran", forKey: "firstRun")
            let alert = UIAlertController(title: "Heads up", message: "In order to use the blocking features, you must enable filtering in settings.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Watch Install Video", style: .default, handler: { (action) in
                guard let path = Bundle.main.path(forResource: "tutorial", ofType:"MOV") else {
                    debugPrint("tutorial.MOV not found")
                    return
                }
                let player = AVPlayer(url: URL(fileURLWithPath: path))
                let playerController = AVPlayerViewController()
                playerController.player = player
                self.present(playerController, animated: true) {
                    player.play()
                }
            }))
            
            present(alert, animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        smartFilterSwitch.isEnabled = KeychainSwift().get("plan") != nil
        smartFilterSwitch.isOn = KeychainSwift().get("plan") != nil && KeychainSwift().get("filter") != nil && KeychainSwift().getBool("filter") == true

        if let plan = KeychainSwift().get("plan") {
            switch plan {
            case "YearlySubscription": startFilterCell.textLabel?.text = "Yearly Member"
            case "MonthlySubscription": startFilterCell.textLabel?.text = "Monthly Member"
            case "LifetimeOnetime": startFilterCell.textLabel?.text = "Lifetime Member"
            default: break
            }
            
            if smartFilterSwitch.isOn {
                filterStatusCell.detailTextLabel?.text = "Running"
                filterStatusCell.detailTextLabel?.textColor = UIColor(named: "Green")
            } else {
                filterStatusCell.detailTextLabel?.text = "Manual Only"
                filterStatusCell.detailTextLabel?.textColor = .orange
            }
        }
    }
    
    @objc func smartSwitchValueChanged(sender: UISwitch) {
        KeychainSwift().set(sender.isOn, forKey: "filter")
        
        if sender.isOn {
            filterStatusCell.detailTextLabel?.text = "Running"
            filterStatusCell.detailTextLabel?.textColor = UIColor(named: "Green")
        } else {
            filterStatusCell.detailTextLabel?.text = "Manual Only"
            filterStatusCell.detailTextLabel?.textColor = .orange
        }
    }
    
    // MARK: - Actions
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch tableView.cellForRow(at: indexPath) {
        case startFilterCell:
            if !pro {
                performSegue(withIdentifier: "showMemberships", sender: self)
            }
        case filterStatusCell:
            if !pro {
                performSegue(withIdentifier: "showMemberships", sender: self)
            }
        case checkForUpdates:
            downloadData()
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func startUpdating() {
        activity.startAnimating()
        checkForUpdates.accessoryView = activity
    }
    
    @objc func setUpdated() {
        checkForUpdates.accessoryView = nil
        checkForUpdates.accessoryType = .checkmark
    }
    
    func downloadData() {
        startUpdating()
        downloader.downloadDetectionData()
        perform(#selector(setUpdated), with: nil, afterDelay: 4.5)
    }
    
    let segueBlockListViewController = "SegueBlockListTableViewController"
    let segueWhitelistViewController = "SegueWhitelistTableViewController"
    let segueMemberListViewController = "SegueMemberListTableViewController"

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueBlockListViewController || segue.identifier == segueWhitelistViewController {
            if let destinationViewController = segue.destination as? ListTableViewController {
                destinationViewController.title = ""
                destinationViewController.managedObjectContext = coreDataManager.mainManagedObjectContext
                destinationViewController.listType = segue.identifier == segueBlockListViewController ? .blocked : .allowed
            }
        } else if segue.identifier == segueMemberListViewController {
            if let destinationViewController = segue.destination as? MembershipTableViewController {
                destinationViewController.managedObjectContext = coreDataManager.backgroundManagedObjectContext
            }
        }
    }
}

