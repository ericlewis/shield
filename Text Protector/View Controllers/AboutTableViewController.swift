//
//  AboutTableViewController.swift
//  Text Protector
//
//  Created by Eric Lewis on 6/24/18.
//  Copyright © 2018 Eric Lewis Innovations, LLC. All rights reserved.
//

import UIKit
import MessageUI
import SwiftyStoreKit
import KeychainSwift
import AVKit
import AVFoundation

class AboutTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var howToInstallCell: UITableViewCell!
    @IBOutlet weak var faqCell: UITableViewCell!
    @IBOutlet weak var privacyPolicyCell: UITableViewCell!
    @IBOutlet weak var restorePurchasesCell: UITableViewCell!
    @IBOutlet weak var rateCell: UITableViewCell!
    @IBOutlet weak var shareCell: UITableViewCell!
    @IBOutlet weak var twitterCell: UITableViewCell!
    @IBOutlet weak var contactCell: UITableViewCell!

    let activity = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    var alert: UIAlertController?
    
    override func viewDidLoad() {
        howToInstallCell.imageView?.image = UIImage(named: "howToInstall")
        faqCell.imageView?.image = UIImage(named: "about")
        privacyPolicyCell.imageView?.image = UIImage(named: "privacyPolicy")
        restorePurchasesCell.imageView?.image = UIImage(named: "restorePurchases")
        rateCell.imageView?.image = UIImage(named: "rate")
        shareCell.imageView?.image = UIImage(named: "recommend")
        twitterCell.imageView?.image = UIImage(named: "twitter")
        contactCell.imageView?.image = UIImage(named: "contactUs")
        
        activity.color = .orange

        if pro {
            restorePurchasesCell.imageView?.image = UIImage(named: "update")
            restorePurchasesCell.textLabel?.text = "Check for Updates"
        }
    }
    
    // MARK: - Actions

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch tableView.cellForRow(at: indexPath) {
        case howToInstallCell:
            guard let path = Bundle.main.path(forResource: "tutorial", ofType:"MOV") else {
                debugPrint("tutorial.MOV not found")
                return
            }
            let player = AVPlayer(url: URL(fileURLWithPath: path))
            let playerController = AVPlayerViewController()
            playerController.player = player
            present(playerController, animated: true) {
                player.play()
            }
        case faqCell:
            print("how to install")
        case privacyPolicyCell:
            print("how to install")
        case restorePurchasesCell:
            if !pro {
                SwiftyStoreKit.restorePurchases(atomically: true) { results in
                    var restored = false
                    
                    for purchase in results.restoredPurchases {
                        restored = true
                        KeychainSwift().set(purchase.productId, forKey: "plan")
                    }
                    
                    if restored {
                        self.alert = UIAlertController(title: "Purchases restored!", message: nil, preferredStyle: .alert)
                        self.present(self.alert!, animated: true)
                        self.perform(#selector(AboutTableViewController.dismissAlert), with: nil, afterDelay: 2)
                    } else {
                        self.alert = UIAlertController(title: "Nothing to restore", message: nil, preferredStyle: .alert)
                        self.present(self.alert!, animated: true)
                        self.perform(#selector(AboutTableViewController.dismissAlert), with: nil, afterDelay: 2)
                    }
                }
            } else {
                downloadData()
            }
            
        case rateCell:
            if pro {
                if let url = URL(string: "itms-apps://itunes.apple.com/app/id1406101042?action=write-review") {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }
            } else {
                if let url = URL(string: "itms-apps://itunes.apple.com/app/id1405358230?action=write-review") {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }
            }
            
        case shareCell:
            showShareSheet()
        case twitterCell:
            if let url = URL(string: "https://www.twitter.com/shieldblocker") {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        case contactCell:
            showContactUs()
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc func dismissAlert() {
        alert?.dismiss(animated: true)
    }
    
    func showShareSheet() {
        if pro {
            let shareSheet = UIActivityViewController(activityItems: ["Check out Shield Pro, the smart SMS filter for blocking spam!", URL(string: "https://itunes.apple.com/app/id1406101042")!], applicationActivities: nil)
            
            present(shareSheet, animated: true)
        } else {
            let shareSheet = UIActivityViewController(activityItems: ["Check out Shield, the smart SMS filter for blocking spam!", URL(string: "https://itunes.apple.com/app/id1405358230")!], applicationActivities: nil)
            
            present(shareSheet, animated: true)
        }
        
    }
    
    func showContactUs() {
        let composeVC = MFMailComposeViewController()
        composeVC.setToRecipients(["shieldsmsblocker@gmail.com"])
        if pro {
            composeVC.setSubject("Shield Pro")
        } else {
            composeVC.setSubject("Shield")
        }
        composeVC.mailComposeDelegate = self
        present(composeVC, animated: true)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    func startUpdating() {
        activity.startAnimating()
        restorePurchasesCell.accessoryView = activity
    }
    
    @objc func setUpdated() {
        restorePurchasesCell.accessoryView = nil
        restorePurchasesCell.accessoryType = .checkmark
    }
    
    func downloadData() {
        startUpdating()
        Downloader().downloadDetectionData()
        perform(#selector(setUpdated), with: nil, afterDelay: 4.5)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PrivacyPolicySegue" {
            if let destinationViewController = segue.destination as? WebViewController {
                destinationViewController.title = "Privacy Policy"
                destinationViewController.fileName = "privacy"
            }
        } else if segue.identifier == "FAQSegue" {
            if let destinationViewController = segue.destination as? WebViewController {
                destinationViewController.title = "FAQ"
                destinationViewController.fileName = "faq"
            }
        }
    }
}
