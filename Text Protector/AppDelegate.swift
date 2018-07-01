//
//  AppDelegate.swift
//  Text Protector
//
//  Created by Eric Lewis on 6/24/18.
//  Copyright © 2018 Eric Lewis Innovations, LLC. All rights reserved.
//

import UIKit
import AWSCore
import Analytics
import SwiftyStoreKit
import KeychainSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // MARK: - App Lifecycle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        if UserDefaults.standard.string(forKey: "firstRun") == nil && !pro {
            KeychainSwift().clear()
        }
        
        initializeSegmentIO()
        initializeAWS()
        
        if !pro {
            initializePurchases()
        } else {
            KeychainSwift().set("LifetimeOnetime", forKey: "plan")
        }

        return true
    }

    // MARK: - Setup
    
    func initializeAWS() {
        let credentialProvider = AWSCognitoCredentialsProvider(
            regionType: .USWest2,
            identityPoolId: "us-west-2:1f17d29e-a0a7-4544-8a2b-d0a0799e5471"
        )
        
        let serviceConfiguration = AWSServiceConfiguration(
            region: .USWest2,
            credentialsProvider: credentialProvider
        )
        
        AWSServiceManager.default().defaultServiceConfiguration = serviceConfiguration
    }
    
    func initializeSegmentIO() {
        let config = SEGAnalyticsConfiguration(writeKey: "FIxZCg4clxJumHI7xsQ2cZBQtNcWx1Rx")
        config.trackApplicationLifecycleEvents = true
        config.recordScreenViews = true
        
        SEGAnalytics.setup(with: config)
    }
    
    func initializePurchases() {
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    let downloads = purchase.transaction.downloads
                    if !downloads.isEmpty {
                        SwiftyStoreKit.start(downloads)
                    } else if purchase.needsFinishTransaction {
                        KeychainSwift().set(purchase.productId, forKey: "plan")
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    print("\(purchase.transaction.transactionState.debugDescription): \(purchase.productId)")
                case .failed, .purchasing, .deferred:
                    break // do nothing
                }
            }
        }
        
        SwiftyStoreKit.updatedDownloadsHandler = { downloads in
            // contentURL is not nil if downloadState == .finished
            let contentURLs = downloads.compactMap { $0.contentURL }
            if contentURLs.count == downloads.count {
                print("Saving: \(contentURLs)")
                SwiftyStoreKit.finishTransaction(downloads[0].transaction)
            }
        }
        
        let appleValidator = AppleReceiptValidator(service: .sandbox, sharedSecret: "c387348240004a40af7da26a8dde21aa")
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            switch result {
            case .success(let receipt):
                let productId = "LifetimeOnetime"

                // Verify the purchase of a Subscription
                let purchaseResult = SwiftyStoreKit.verifyPurchase(productId: productId, inReceipt: receipt)
                
                switch purchaseResult {
                case .purchased:
                    KeychainSwift().set(productId, forKey: "plan")
                case .notPurchased:
                    let productId = "MonthlySubscription"
                    
                    // Verify the purchase of a Subscription
                    let purchaseResult = SwiftyStoreKit.verifySubscription(
                        ofType: .autoRenewable, // or .nonRenewing (see below)
                        productId: productId,
                        inReceipt: receipt)
                    
                    switch purchaseResult {
                    case .purchased( _, _):
                        KeychainSwift().set(productId, forKey: "plan")
                        return
                    case .expired( _, _):
                        KeychainSwift().delete("plan")
                        return
                    case .notPurchased:
                        let productId = "YearlySubscription"
                        
                        // Verify the purchase of a Subscription
                        let purchaseResult = SwiftyStoreKit.verifySubscription(
                            ofType: .autoRenewable, // or .nonRenewing (see below)
                            productId: productId,
                            inReceipt: receipt)
                        
                        switch purchaseResult {
                        case .purchased( _, _):
                            KeychainSwift().set(productId, forKey: "plan")
                            return
                        case .expired( _, _):
                            KeychainSwift().delete("plan")
                            return
                        case .notPurchased:
                            print("The user has never purchased \(productId)")
                        }
                    }
                }
                
            case .error(let error):
                print("Receipt verification failed: \(error)")
            }
        }
    }
}

