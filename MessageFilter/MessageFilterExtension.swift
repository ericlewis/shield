//
//  MessageFilterExtension.swift
//  MessageFilter
//
//  Created by Eric Lewis on 6/24/18.
//  Copyright © 2018 Eric Lewis Innovations, LLC. All rights reserved.
//

import IdentityLookup
import CoreData
import KeychainSwift

final class MessageFilterExtension: ILMessageFilterExtension {}

extension MessageFilterExtension: ILMessageFilterQueryHandling {
    
    fileprivate var coreDataManager: CoreDataManager {
        return CoreDataManager(modelName: "Lists")
    }

    func handle(_ queryRequest: ILMessageFilterQueryRequest, context: ILMessageFilterExtensionContext, completion: @escaping (ILMessageFilterQueryResponse) -> Void) {
        
        let managedObjectContext = coreDataManager.backgroundManagedObjectContext
        let response = ILMessageFilterQueryResponse()
        
        let localLookup = localLookupAction(for: queryRequest, context: managedObjectContext)
        if localLookup != .none {
            response.action = localLookup
            completion(response)
            return
        }
        
        // And finally use AI if the above two fail
        if let filter = KeychainSwift().getBool("filter") {
            if filter {
                response.action = analyzerAction(for: queryRequest)
                completion(response)
                return
            }
        }
        
        response.action = .none
        completion(response)
    }
    
    private func analyzerAction(for queryRequest: ILMessageFilterQueryRequest) -> ILMessageFilterAction {
        guard let message = queryRequest.messageBody else {
            return .allow
        }
        
        if Analyzer().sentiment(forMessage: message) == .spam {
            return .filter
        } else {
            return .allow
        }
    }
    
    private func localLookupAction(for queryRequest: ILMessageFilterQueryRequest, context: NSManagedObjectContext) -> ILMessageFilterAction {
        guard let sender = queryRequest.sender, let message = queryRequest.messageBody?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return .none
        }
        
        let phoneResult = findItemPhone(context: context, text: sender)

        // only process message if we don't have a phone
        if phoneResult.count == 0 {
            return process(result: findItem(context: context, text: message))
        }
        
        return process(result: phoneResult)
    }
    
    private func process(result: [Item]) -> ILMessageFilterAction {
        if result.count > 0 {
            if let category = result.first?.category {
                if category == "blocked" {
                    return .filter
                } else {
                    return .allow
                }
            }
        }
        
        return .none
    }
    
    private func findItemPhone(context: NSManagedObjectContext, text: String) -> [Item] {
        let userFetch = NSFetchRequest<Item>(entityName: "Item")
        userFetch.fetchLimit = 1
        userFetch.predicate = NSPredicate(format: "title CONTAINS[cd] %@", text)
        return try! context.fetch(userFetch)
    }
    
    private func findItem(context: NSManagedObjectContext, text: String) -> [Item] {
        let userFetch = NSFetchRequest<Item>(entityName: "Item")
        userFetch.fetchLimit = 1
        userFetch.predicate = NSPredicate(format: "title CONTAINS[cd] %@", text)
        return try! context.fetch(userFetch)
    }
}
