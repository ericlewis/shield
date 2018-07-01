//
//  TestFilterTableViewController.swift
//  Text Protector
//
//  Created by Eric Lewis on 6/24/18.
//  Copyright © 2018 Eric Lewis Innovations, LLC. All rights reserved.
//

import UIKit
import Analytics

class TestFilterTableViewController: UITableViewController, UITextViewDelegate {

    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var resultSubtitleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var submitButton: UIBarButtonItem!
    @IBOutlet weak var resultCell: UITableViewCell!
    
    let analyzer = Analyzer()
    
    var selectedType = Analyzer.MessageType.ham
    var alert: UIAlertController?
    
    override func viewDidLoad() {
        resultCell.imageView?.image = UIImage(named: "waiting")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        textView.becomeFirstResponder()
    }
    
    @IBAction func submit(_ sender: Any) {
        alert = UIAlertController(title: "Report Correction", message: "Choose the correct category", preferredStyle: .alert)
        
        // Report Normal
        alert?.addAction(UIAlertAction(title: "Normal", style: .default, handler: { (action) in
            self.reportMessage(type: .ham, text: self.textView.text!)
        }))
        
        // Report bug
        alert?.addAction(UIAlertAction(title: "Spam", style: .destructive, handler: { (action) in
            self.reportMessage(type: .spam, text: self.textView.text!)
        }))
        
        // Cancel
        alert?.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            
        }))

        present(alert!, animated: true)
    }
    
    func reportMessage(type: Analyzer.MessageType, text: String) {
        textView.text = nil
        
        let properties = ["type": type.rawValue,
                          "text": text.trimmingCharacters(in: .whitespacesAndNewlines)]
        
        SEGAnalytics.shared().track("report_sms", properties: properties)
        
        alert = UIAlertController(title: nil, message: "🎉\nMessage Reported! Thanks!", preferredStyle: .alert)
        present(alert!, animated: true)
        perform(#selector(dismissAlert), with: nil, afterDelay: 1)
    }
        
    @objc func dismissAlert() {
        alert?.dismiss(animated: true)
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        guard let text = textView.text else {
            return
        }
        
        if text.count == 0 {
            submitButton.isEnabled = false
            resultLabel.text = "Start Typing..."
            resultLabel.textColor = .gray
            resultSubtitleLabel.text = ""
            resultCell.imageView?.image = UIImage(named: "waiting")
            return
        }
        
        submitButton.isEnabled = true
        
        let sentiment = analyzer.sentiment(forMessage: text)
        
        if sentiment == .ham {
            resultLabel.text = "Normal"
            resultSubtitleLabel.text = "Useful, Not Spam"
            resultLabel.textColor = UIColor(named: "Green")
            resultCell.imageView?.image = UIImage(named: "ham")
            selectedType = .ham
        } else {
            resultLabel.text = "Spam"
            resultSubtitleLabel.text = "Ads, Promotions, Phishing, Scams"
            resultLabel.textColor = UIColor(named: "Red")
            resultCell.imageView?.image = UIImage(named: "spam")
            selectedType = .spam
        }
    }
}
