//
//  SquareCollection.swift
//  Mongosquare
//
//  Created by Sean Park on 7/15/18.
//  Copyright © 2018 0hoo. All rights reserved.
//

import Foundation

struct SquareCollection: SquareModel {
    var name: String
    var fullName: String
    
    let collection: Collection // use MongoKitten Collection till CollectionQueryable is implemented
    var saved: Bool
    
    var subscriptionKey: String {
        return "\(collection.database.server.hostname)/\(collection.database.name)/\(fullName)"
    }
    
    var path: String {
        return collection.database.description + "/" + collection.name
    }
    
    var databaseName: String {
        return collection.database.name
    }
    
    init(collection: Collection) {
        self.name = collection.name
        self.fullName = collection.fullName
        
        self.collection = collection
        self.saved = true
    }
    
    func find(_ filter: Query? = nil, sortedBy sort: Sort? = nil, projecting projection: Projection? = nil, readConcern: ReadConcern? = nil, collation: Collation? = nil, skipping skip: Int? = nil, limitedTo limit: Int? = nil, withBatchSize batchSize: Int = 100) -> [SquareDocument] {
        precondition(batchSize < Int(Int32.max))
        precondition(skip ?? 0 < Int(Int32.max))
        precondition(limit ?? 0 < Int(Int32.max))
        guard let documents = try? collection.find(filter, sortedBy: sort, projecting: projection, readConcern: readConcern, collation: collation, skipping: skip, limitedTo: limit, withBatchSize: batchSize) else { return [] }
        return documents.map {
            var document = SquareDocument(document: $0)
            document.collectionKey = subscriptionKey
            return document
        }
    }
    
    func count(_ filter: Query? = nil, limitedTo limit: Int? = nil, skipping skip: Int? = nil, readConcern: ReadConcern? = nil, collation: Collation? = nil) -> Int {
        return (try? collection.count(filter, limitedTo: limit, skipping: skip, readConcern: readConcern, collation: collation)) ?? 0
    }
    
    @discardableResult
    public func insert(_ document: SquareDocument, stoppingOnError ordered: Bool? = nil, writeConcern: WriteConcern? = nil, timingOut afterTimeout: DispatchTimeInterval? = nil) throws -> BSON.Primitive {
        return try collection.insert(document.document, stoppingOnError: ordered, writeConcern: writeConcern, timingOut: afterTimeout)
    }
    
    func update(_ document: SquareDocument) -> Int {
        print("org:\(document)")
        var updated = document
        let query = Query(["_id": updated.id])
        do {
            print("before:\(updated)")
            
            let r = try update(query, to: updated, stoppingOnError: true)
            
            print("after:\(updated)")
            print("after org:\(document)")
            SquareStore.modelUpdated(updated)
            return r
        } catch {
            print(error)
            return 0
        }
    }
    
    @discardableResult
    func update(_ filter: Query = [:], to updated: SquareDocument, upserting upsert: Bool = false, multiple multi: Bool = false, writeConcern: WriteConcern? = nil, stoppingOnError ordered: Bool? = nil) throws -> Int {
        
        
        return try collection.update(filter, to: updated.document, upserting: upsert, multiple: multi, writeConcern: writeConcern, stoppingOnError: ordered)
    }
}
