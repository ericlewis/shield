//
//  ReportSMSTableViewController.swift
//  Text Protector
//
//  Created by Eric Lewis on 6/24/18.
//  Copyright © 2018 Eric Lewis Innovations, LLC. All rights reserved.
//

import UIKit
import Analytics

class ReportSMSTableViewController: UITableViewController, UITextViewDelegate {

    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var spamCell: UITableViewCell!
    @IBOutlet weak var normalCell: UITableViewCell!
    
    @IBOutlet weak var pasteCell: UITableViewCell!
    let pasteSwitch = UISwitch()
    
    var selectedType = Analyzer.MessageType.spam
    var alert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spamCell.imageView?.image = UIImage(named: "spam")
        normalCell.imageView?.image = UIImage(named: "ham")

        pasteSwitch.addTarget(self, action: #selector(pasteValueChanged), for: .valueChanged)
        pasteSwitch.isOn = UserDefaults.standard.bool(forKey: "AutoPaste")
        pasteCell.accessoryView = pasteSwitch
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if pasteSwitch.isOn {
            textView.text = UIPasteboard.general.string
        }
    }
    
    @objc func pasteValueChanged(sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "AutoPaste") //Bool
    }
    
    // MARK: - Actions

    @IBAction func doneTapped(_ sender: Any) {
        textView.text = nil
        
        let properties = ["type": selectedType.rawValue,
                          "text": textView.text.trimmingCharacters(in: .whitespacesAndNewlines)] as [String: String]
        
        SEGAnalytics.shared().track("report_sms", properties: properties)
        
        alert = UIAlertController(title: nil, message: "🎉\nMessage Reported! Thanks!", preferredStyle: .alert)
        present(alert!, animated: true)
        perform(#selector(dismissAlert), with: nil, afterDelay: 1)
    }
    
    @objc func dismissAlert() {
        alert?.dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch tableView.cellForRow(at: indexPath) {
        case spamCell:
            spamCell.accessoryType = .checkmark
            normalCell.accessoryType = .none
            selectedType = .spam
        case normalCell:
            spamCell.accessoryType = .none
            normalCell.accessoryType = .checkmark
            selectedType = .ham
        default:
            break
        }
        
    }
    
    func textViewDidChange(_ textView: UITextView) {
        doneButton.isEnabled = textView.text.count > 0
    }
}
