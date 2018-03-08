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
    
    func insert(document: SquareDocument) -> SquareDocument? {
        return nil
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
    func update(_ filter: Query = [:], to updated: SquareDocument, upserting upsert: Bool = false, multiple multi: Bool = false, writeConcern: WriteConcern? = nil, stoppingOnError ordered: Bool? = nil) throws -> Int {
        
        
        return try collection.update(filter, to: updated.document, upserting: upsert, multiple: multi, writeConcern: writeConcern, stoppingOnError: ordered)
    }
}


typealias DocumentIndexIterationElement = (key: String, value: Any, type: SquareDocument.ElementType?)

struct SquareDocument: Swift.Collection {
    
    enum ElementType: Byte, CustomStringConvertible {
        case double = 0x01
        case string = 0x02
        case document = 0x03
        case arrayDocument = 0x04
        case binary = 0x05
        case objectId = 0x07
        case boolean = 0x08
        case utcDateTime = 0x09
        case nullValue = 0x0A
        case regex = 0x0B
        case javascriptCode = 0x0D
        case javascriptCodeWithScope = 0x0F
        case int32 = 0x10
        case timestamp = 0x11
        case int64 = 0x12
        case decimal128 = 0x13
        case minKey = 0xFF
        case maxKey = 0x7F
        
        var description : String {
            switch self {
            case .double: return "Double"
            case .string: return "String"
            case .document: return "Document"
            case .arrayDocument: return "Array Document"
            case .binary: return "Binary"
            case .objectId: return "objectId"
            case .boolean: return "Boolean"
            case .utcDateTime: return "Datetime"
            case .nullValue: return "null"
            case .regex: return "regex"
            case .javascriptCode: return "JavaScript code"
            case .javascriptCodeWithScope: return "JavaScript code with Scope"
            case .int32: return "Int32"
            case .timestamp: return "Timestamp"
            case .int64: return "Int64"
            case .decimal128: return "Decimal"
            case .minKey: return "Min Key"
            case .maxKey: return "Max Key"
            }
        }
    }
    
    var document: MongoKitten.Document
    var keys: [String] {
        return document.keys
    }
    
    init(document: MongoKitten.Document) {
        self.document = document
    }
    
    func type(at key: Int) -> ElementType? {
        if let type = document.type(at: key) {
            return ElementType(rawValue: type.rawValue)
        }
        return nil
    }
    
    func type(at key: String) -> ElementType? {
        if let type = document.type(at: key) {
            return ElementType(rawValue: type.rawValue)
        }
        return nil 
    }
    
    subscript(key: String) -> Primitive? {
        get {
            return document[key.components(separatedBy: ".")]
        }
        set {
            document[key.components(separatedBy: ".")] = newValue
        }
    }
    
    func makeIterator() -> AnyIterator<DocumentIndexIterationElement> {
        let documentIterator = document.makeIterator()
        return AnyIterator {
            guard let doc = documentIterator.next() else { return nil }
            
            return DocumentIndexIterationElement(key: doc.key, value: doc.value, type: self.type(at: doc.key))
        }
    }
    
    mutating func set(value: String, forKey key: String, type: ElementType) -> Bool {
        switch type {
        case .double:
            if let value = Double(value) {
                document[key] = value
            }
        case .string:
            document[key] = value
        case .boolean:
            if let value = Bool(value) {
                let booleanPrimitive: Primitive = value
                document[key] = booleanPrimitive
            }
        case .int32:
            if let value = Int32(value) {
               document[key] = value
            }
        case .int64:
            if let value = Double(value) {
                document[key] = value
            }
        default:
            return false
        }
        return true
    }
    
    mutating func removeValue(forKey key: String) {
        document.removeValue(forKey: key)
    }
    
    ///
    ///
    /// Index
    
    var startIndex: DocumentIndex {
        return document.startIndex
    }
    
    var endIndex: DocumentIndex {
        return document.endIndex
    }
    
    func index(after i: DocumentIndex) -> DocumentIndex {
        return document.index(after: i)
    }
    
    subscript(position: DocumentIndex) -> DocumentIndexIterationElement {
        return DocumentIndexIterationElement(key: document[position].key, value: document[position].value, type: type(at: document[position].key))
    }
}
