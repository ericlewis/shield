//
//  Util.swift
//  SentimentAnalysis
//
//  Created by Martin Mitrevski on 09.07.17.
//  Copyright © 2017 Martin Mitrevski. All rights reserved.
//

import Foundation
import CoreML


class Analyzer {
    
    enum MessageType: String {
        case spam = "spam"
        case ham  = "ham"
    }

    func sentiment(forMessage text: String) -> MessageType {
        let bagOfWords = bow(text: text)
        
        let compiledUrl = try! FileManager.default.url(for: .applicationSupportDirectory,
                                                               in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("SpamClassifier.mlmodelc")
        
        
        guard let localOutput = try? SpamClassifier(contentsOf: compiledUrl).prediction(text: bagOfWords) else {
            guard let compiledOutput = try? SpamClassifier().prediction(text: bagOfWords) else {
                print("Error producing type, setting ham as default")
                return .ham
            }
            
            return sentiment(forPrediction: compiledOutput)
        }
        
        return sentiment(forPrediction: localOutput)
    }
    
    private func sentiment(forPrediction prediction: SpamClassifierOutput) -> MessageType {
        if prediction.type == "spam" {
            return .spam
        }
        
        return .ham
    }
    
    func bow(text: String) -> [String: Double] {
        var bagOfWords = [String: Double]()
        
        let tagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
        let range = NSRange(location: 0, length: text.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
        tagger.string = text
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .tokenType, options: options) { _, tokenRange, _ in
            let word = (text as NSString).substring(with: tokenRange)
            if bagOfWords[word] != nil {
                bagOfWords[word]! += 1
            } else {
                bagOfWords[word] = 1
            }
        }
        
        return bagOfWords
    }
}

