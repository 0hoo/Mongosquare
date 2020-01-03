//
//  Database.swift
//  Mongosquare
//
//  Created by Sean Park on 2/16/18.
//  Copyright © 2018 0hoo. All rights reserved.
//

import Foundation
import MongoKitten

struct SquareDatabase: SquareModel {
    var saved: Bool = false
    var collections: [SquareCollection] = []
    let database: MongoDatabase
    let name: String
    
    var subscriptionKey: String {
        return database.name
        //return "\(database.server.hostname)/\(name)"
    }
    
    init(database: MongoDatabase, saved: Bool = true) {
        self.name = database.name
        self.database = database
        
        //let kittenCollections = (try? Array(database.listCollections())) ?? []
        if let mongoCollections = try? database.listCollections().wait() {
            self.collections = mongoCollections.map { SquareCollection(collection: $0) }
        }
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
