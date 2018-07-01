//
//  Item.swift
//  Text Protector
//
//  Created by Eric Lewis on 6/26/18.
//  Copyright © 2018 Eric Lewis Innovations, LLC. All rights reserved.
//

import Foundation

extension Item {
    
    // MARK: - Dates
    var updatedAtAsDate: Date {
        guard let updatedAt = updatedAt else { return Date() }
        return Date(timeIntervalSince1970: updatedAt.timeIntervalSince1970)
    }
    
    var createdAtAsDate: Date {
        guard let createdAt = createdAt else { return Date() }
        return Date(timeIntervalSince1970: createdAt.timeIntervalSince1970)
    }

}
