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
    var collections: [SquareCollection] = []
    let database: MongoKitten.Database
    let name: String
    
    init(database: MongoKitten.Database) {
        self.name = database.name
        self.database = database 
        let kittenCollections = (try? Array(database.listCollections())) ?? []
        self.collections = kittenCollections.map { SquareCollection(collection: $0) }
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
}

struct SquareCollection {
    var name: String
    var fullName: String
    
    let collection: MongoKitten.Collection // use MongoKitten Collection till CollectionQueryable is implemented
    var isSaved: Bool
    
    var databaseName: String {
        return collection.database.name
    }
    
    init(collection: MongoKitten.Collection) {
        self.name = collection.name
        self.fullName = collection.fullName
        
        self.collection = collection 
        self.isSaved = true 
    }
    
    func find(_ filter: Query? = nil, sortedBy sort: Sort? = nil, projecting projection: Projection? = nil, readConcern: ReadConcern? = nil, collation: Collation? = nil, skipping skip: Int? = nil, limitedTo limit: Int? = nil, withBatchSize batchSize: Int = 100) -> [SquareDocument] {
        precondition(batchSize < Int(Int32.max))
        precondition(skip ?? 0 < Int(Int32.max))
        precondition(limit ?? 0 < Int(Int32.max))
        guard let documents = try? collection.find(filter, sortedBy: sort, projecting: projection, readConcern: readConcern, collation: collation, skipping: skip, limitedTo: limit, withBatchSize: batchSize) else { return [] }
        return documents.map { SquareDocument(document: $0) }
    }
    
    func count(_ filter: Query? = nil, limitedTo limit: Int? = nil, skipping skip: Int? = nil, readConcern: ReadConcern? = nil, collation: Collation? = nil) -> Int {
        return (try? collection.count(filter, limitedTo: limit, skipping: skip, readConcern: readConcern, collation: collation)) ?? 0
    }
    
    @discardableResult
    public func insert(_ document: SquareDocument, stoppingOnError ordered: Bool? = nil, writeConcern: WriteConcern? = nil, timingOut afterTimeout: DispatchTimeInterval? = nil) throws -> BSON.Primitive {
        return try collection.insert(document.document, stoppingOnError: ordered, writeConcern: writeConcern, timingOut: afterTimeout)
    }
    
    @discardableResult
    func update(_ filter: Query = [:], to updated: SquareDocument, upserting upsert: Bool = false, multiple multi: Bool = false, writeConcern: WriteConcern? = nil, stoppingOnError ordered: Bool? = nil) throws -> Int {
        
        
        return try collection.update(filter, to: updated.document, upserting: upsert, multiple: multi, writeConcern: writeConcern, stoppingOnError: ordered)
    }
}
