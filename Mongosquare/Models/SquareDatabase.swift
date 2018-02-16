//
//  Database.swift
//  Mongosquare
//
//  Created by Sean Park on 2/16/18.
//  Copyright © 2018 0hoo. All rights reserved.
//

import Foundation
import MongoKitten

struct SquareDatabase {
    var isSaved: Bool = false
    let name: String
    
    init(database: Database) {
       self.name = database.name
    }
    
    static func create(collection: String) -> Collection? {
        return nil
    }
}

struct SquareCollection {
    var name: String
    
    func insert(document: SquareDocument) -> SquareDocument? {
        return nil
    }
}

struct SquareDocument {
    
}
