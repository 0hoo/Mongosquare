//
// This source file is part of the MongoKitten open source project
//
// Copyright (c) 2016 - 2017 OpenKitten and the MongoKitten project authors
// Licensed under MIT
//
// See https://github.com/OpenKitten/MongoKitten/blob/mongokitten31/LICENSE.md for license information
// See https://github.com/OpenKitten/MongoKitten/blob/mongokitten31/CONTRIBUTORS.md for the list of MongoKitten project authors
//

import BSON

/// DBRef is a structure made to keep references to other MongoDB objects and resolve them easily
public struct DBRef: ValueConvertible {
    /// The collection this referenced Document resides in
    public var collection: Collection
    
    /// The referenced Document's _id
    public var id: BSON.Primitive
    
    /// Converts this DBRef to a BSON.Primitive for easy embedding
    public func makePrimitive() -> BSON.Primitive {
        return self.documentValue
    }
    
    /// Creates a DBRef
    ///
    /// - parameter reference: The _id of the referenced object
    /// - parameter collection: The collection where this references object resides
    public init(referencing reference: BSON.Primitive, inCollection collection: Collection) {
        self.id = reference
        self.collection = collection
    }
    
    /// Initializes this DBRef with a Primitive.
    ///
    /// This initializer fails when the Primitive isn't a valid DBRef Document
    public init?(_ primitive: Primitive?, inServer server: Server) {
        guard let document = Document(primitive) else {
            return nil
        }
        
        self.init(document, inServer: server)
    }
    
    /// Initializes this DBRef with a Primitive.
    ///
    /// This initializer fails when the Primitive isn't a valid DBRef Document
    public init?(_ primitive: Primitive?, inDatabase database: Database) {
        guard let document = Document(primitive) else {
            return nil
        }
        
        self.init(document, inDatabase: database)
    }
    
    /// Initializes this DBRef with a Document.
    ///
    /// This initializer fails when the Document isn't a valid DBRef Document
    public init?(_ document: Document, inServer server: Server) {
        guard let database = String(document["$db"]), let collection = String(document["$ref"]) else {
            log.debug("Provided DBRef document is not valid")
            log.debug(document)
            return nil
        }
        
        guard let id = document["$id"] else {
            return nil
        }
        
        self.collection = server[database][collection]
        self.id = id
    }
    
    /// Initializes this DBRef with a Document.
    ///
    /// This initializer fails when the Document isn't a valid DBRef Document
    public init?(_ document: Document, inDatabase database: Database) {
        guard let collection = String(document["$ref"]) else {
            return nil
        }
        
        guard let id = document["$id"] else {
            return nil
        }
        
        self.collection = database[collection]
        self.id = id
    }
    
    /// The Document representation of this DBRef
    public var documentValue: Document {
        return [
            "$ref": self.collection.name,
            "$id": self.id,
            "$db": self.collection.database.name
        ]
    }
    
    /// Resolves this reference to a Document
    ///
    /// - returns: The Document or `nil` if the reference is invalid or the Document has been removed.
    public func resolve() throws -> Document? {
        return try collection.findOne("_id" == self.id)
    }
}
