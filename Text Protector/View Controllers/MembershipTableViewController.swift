//
//  MembershipTableViewController.swift
//  Text Protector
//
//  Created by Eric Lewis on 6/28/18.
//  Copyright © 2018 Eric Lewis Innovations, LLC. All rights reserved.
//

import UIKit
import CoreData
import SwiftyStoreKit
import KeychainSwift

class MembershipTableViewController: UITableViewController {
    
    @IBOutlet weak var goldCell: UITableViewCell!
    @IBOutlet weak var silverCell: UITableViewCell!
    @IBOutlet weak var lifetimeCell: UITableViewCell!
    @IBOutlet weak var freeCell: UITableViewCell!
    
    let activity = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    let activity2 = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    let activity3 = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    fileprivate let downloader = Downloader()
    
    var managedObjectContext: NSManagedObjectContext?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activity.startAnimating()
        activity.color = .orange
        
        activity2.startAnimating()
        activity2.color = .orange
        
        activity3.startAnimating()
        activity3.color = .orange

        goldCell.detailTextLabel?.text = nil
        silverCell.detailTextLabel?.text = nil
        lifetimeCell.detailTextLabel?.text = nil
        
        goldCell.accessoryView = activity
        silverCell.accessoryView = activity2
        lifetimeCell.accessoryView = activity3
        
        if let plan = KeychainSwift().get("plan") {
            freeCell.accessoryType = .none
            
            switch plan {
                case "YearlySubscription": goldCell.accessoryType = .checkmark
                case "MonthlySubscription": silverCell.accessoryType = .checkmark
                case "LifetimeOnetime": lifetimeCell.accessoryType = .checkmark
                default: break
            }
        }

        SwiftyStoreKit.retrieveProductsInfo(["MonthlySubscription", "YearlySubscription", "LifetimeOnetime"]) { result in
            for product in result.retrievedProducts {
                if let price = product.localizedPrice {
                    let identifier = product.productIdentifier
                    if identifier == "MonthlySubscription" {
                        self.silverCell.detailTextLabel?.text = price
                        self.silverCell.accessoryView = nil
                        self.silverCell.isUserInteractionEnabled = true
                    } else if identifier == "YearlySubscription" {
                        self.goldCell.accessoryView = nil
                        self.goldCell.detailTextLabel?.text = price
                        self.goldCell.isUserInteractionEnabled = true
                    } else if identifier == "LifetimeOnetime" {
                        self.lifetimeCell.detailTextLabel?.text = price
                        self.lifetimeCell.accessoryView = nil
                        self.lifetimeCell.isUserInteractionEnabled = true
                    }
                }
            }
            
            self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var id = ""
        
        switch tableView.cellForRow(at: indexPath) {
        case goldCell:
            id = "YearlySubscription"
        case silverCell:
            id = "MonthlySubscription"
        case lifetimeCell:
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id1406101042") {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
            tableView.deselectRow(at: indexPath, animated: true)
            return
        default:
            return
        }

        SwiftyStoreKit.purchaseProduct(id, quantity: 1, atomically: true) { result in
            self.goldCell.accessoryType = .none
            self.silverCell.accessoryType = .none
            self.lifetimeCell.accessoryType = .none
            self.freeCell.accessoryType = .none
            
            switch result {
            case .success(let purchase):
                switch purchase.productId {
                case "YearlySubscription": self.goldCell.accessoryType = .checkmark
                case "MonthlySubscription": self.silverCell.accessoryType = .checkmark
                case "LifetimeOnetime": self.lifetimeCell.accessoryType = .checkmark
                default: break
                }
                
                self.downloader.managedObjectContext = self.managedObjectContext
                self.downloader.downloadDetectionData()

                KeychainSwift().set(purchase.productId, forKey: "plan")
                KeychainSwift().set(true, forKey: "filter")

                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                
            case .error(let error):
                switch error.code {
                case .unknown: print("Unknown error. Please contact support")
                case .clientInvalid: print("Not allowed to make the payment")
                case .paymentCancelled: break
                case .paymentInvalid: print("The purchase identifier was invalid")
                case .paymentNotAllowed: print("The device is not allowed to make the payment")
                case .storeProductNotAvailable: print("The product is not available in the current storefront")
                case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
                case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
                case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
                }
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
    }

}
