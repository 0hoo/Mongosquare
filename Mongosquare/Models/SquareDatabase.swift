//
//  Database.swift
//  Mongosquare
//
//  Created by Sean Park on 2/16/18.
//  Copyright © 2018 0hoo. All rights reserved.
//

import Foundation

struct SquareDatabase: SquareModel {
    var saved: Bool = false
    var collections: [SquareCollection] = []
    let database: Database
    let name: String
    
    init(database: Database, saved: Bool = true) {
        self.name = database.name
        self.database = database 
        let kittenCollections = (try? Array(database.listCollections())) ?? []
        self.collections = kittenCollections.map { SquareCollection(collection: $0) }
        self.saved = saved
    }
    
    static func create(collection: String) -> SquareCollection? {
        return nil
    }
    
    func reloadCollections() {
        
    }
    
    subscript (name: String) -> SquareCollection {
        let c: SquareCollection = SquareCollection(collection: database[name])
        return c
    }
    
    static func registerUpdate(_ database: SquareDatabase?) {
        
    }
}
