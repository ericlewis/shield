//
//  BlockedTableViewController.swift
//  Text Protector
//
//  Created by Eric Lewis on 6/24/18.
//  Copyright © 2018 Eric Lewis Innovations, LLC. All rights reserved.
//

import UIKit
import CoreData
import PhoneNumberKit
import Analytics

class ListTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    enum ListType {
        case blocked
        case allowed
    }
    
    enum ListFilter: Int {
        case phone
        case keyword
    }
    
    var managedObjectContext: NSManagedObjectContext?

    var shadowImageView: UIImageView?
    var headerView: UIToolbar?
    var segmentedControl: UISegmentedControl?
    
    var listType: ListType?
    var selectedFilter: ListFilter = .phone
    
    let phoneNumberKit = PhoneNumberKit()
    let partialFormatter = PartialFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        
        fetchedResultsController = fetchedResultsControllerFor(type: "phone")
        fetchItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if shadowImageView == nil && listType == .blocked {
            shadowImageView = findShadowImage(under: navigationController!.navigationBar)
        }
        
        shadowImageView?.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shadowImageView?.isHidden = false
    }
    
    func setupViews() {
        if listType == .allowed {
            title = "Whitelist"
        } else {
            title = "Block List"
            headerView = UIToolbar()
            segmentedControl = UISegmentedControl(items: ["Phone Numbers", "Keywords"])
            segmentedControl?.selectedSegmentIndex = selectedFilter.rawValue
            segmentedControl?.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
            
            headerView?.setItems([
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(customView: segmentedControl!), UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
                ], animated: false)
        }

        tableView.allowsSelection = false
    }
    
    // MARK: - Actions

    @IBAction func addTapped(_ sender: Any) {
        if listType == .blocked {
            if selectedFilter == .phone {
                showAlert(title: "Block Phone Number", placeholder: "(415) 867-5309", submitButtonTitle: "Block", submitButtonStyle: .destructive)

            } else {
                showAlert(title: "Block Keyword", placeholder: "Enter Keyword", keyboardType: .default, submitButtonTitle: "Block", submitButtonStyle: .destructive)

            }
            
        } else {
            showAlert(title: "Whitelist Phone Number", submitButtonTitle: "Save")
            
        }
        
    }
    
    func showAlert(title: String, placeholder: String = "(415) 867-5309", keyboardType: UIKeyboardType = .phonePad, submitButtonTitle: String, submitButtonStyle: UIAlertActionStyle = .default) {
        
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        let submitAction = UIAlertAction(title: submitButtonTitle, style: submitButtonStyle) { _ in
            guard let textField = alert.textFields?.first else {
                return
            }
            
            self.submit(text: textField.text)
        }
        submitAction.isEnabled = false

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addTextField { (textField) in
            textField.placeholder = placeholder
            textField.keyboardType = keyboardType
            textField.enablesReturnKeyAutomatically = true
            NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: textField, queue: .main) { (notification) in
                guard let text = textField.text else { return }
                
                if keyboardType == .phonePad {
                    textField.text = self.partialFormatter.formatPartial(text)
                }
                
                submitAction.isEnabled = text != ""
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(submitAction)
        
        present(alert, animated: true)
    }
    
    @objc func segmentedControlValueChanged(sender: UISegmentedControl) {
        selectedFilter = ListFilter(rawValue: sender.selectedSegmentIndex)!
        fetchedResultsController = fetchedResultsControllerFor(type:  selectedFilter == .keyword ? "keyword" : "phone")
        fetchItems()
        tableView.reloadData()
    }
    
    func submit(text: String?) {
        guard var text = text else {
            return
        }
        
        if selectedFilter == .phone {
            do {
                let phoneNumber = try phoneNumberKit.parse(text)
                text = phoneNumberKit.format(phoneNumber, toType: .e164)
            }
            catch {
                print("Invalid phone, just use whatever stupid shit they entered")
            }
        } else {
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        guard let managedObjectContext = managedObjectContext else { return }

        let type = selectedFilter == .phone ? "phone" : "keyword"
        let category = listType == .allowed ? "allowed" : "blocked"

        let item = Item(context: managedObjectContext)
        item.createdAt = Date()
        item.updatedAt = Date()
        item.title = text
        item.type = type
        item.category = category

        try! managedObjectContext.save()
        
        SEGAnalytics.shared().track(category, properties: ["type": type, "text": text] as [String: String])
    }
    
    // MARK: - FetchedResultsController

    fileprivate var fetchedResultsController: NSFetchedResultsController<Item>?
    
    fileprivate func fetchedResultsControllerFor(type: String) -> NSFetchedResultsController<Item> {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "type == %@ AND category == %@ AND hidden == FALSE", type, listType == .blocked ? "blocked" : "allowed")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Item.updatedAt), ascending: false)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }
    
    fileprivate var hasItems: Bool {
        guard let fetchedObjects = fetchedResultsController?.fetchedObjects else { return false }
        return fetchedObjects.count > 0
    }
    
    // MARK: - Helper Methods
    
    private func fetchItems() {
        do {
            try self.fetchedResultsController?.performFetch()
        } catch {
            print("Unable to Perform Fetch Request")
            print("\(error), \(error.localizedDescription)")
        }
    }
}

extension ListTableViewController {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        case .update:
            if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) {
                configure(cell, at: indexPath)
            }
        case .move:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        }
    }
    
}

extension ListTableViewController {
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return listType == .allowed ? 0 : 50
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let sections = fetchedResultsController?.sections else { return 0 }
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = fetchedResultsController?.sections?[section] else { return 0 }
        return section.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        configure(cell, at: indexPath)
        
        return cell
    }
    
    func configure(_ cell: UITableViewCell, at indexPath: IndexPath) {
        var text = fetchedResultsController?.object(at: indexPath).title
        
        if let textGood = text, selectedFilter == .phone {
            text = partialFormatter.formatPartial(textGood)
        }
        
        cell.textLabel?.text = text
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        guard let item = fetchedResultsController?.object(at: indexPath) else { return }
        managedObjectContext?.delete(item)
        try! managedObjectContext?.save()
    }
    
}
