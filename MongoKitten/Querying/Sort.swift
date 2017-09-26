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

/// Defines the order in which a field has to be sorted
public enum SortOrder: ValueConvertible {
    /// Ascending means that we order from "past to future" or from "0 to 10"
    case ascending
    
    /// Descending is opposite of ascending
    case descending
    
    /// Custom can be useful for more complex MongoDB behaviour. Generally not used.
    case custom(BSON.Primitive)
    
    /// Converts the SortOrder to a BSON primitive for easy embedding
    public func makePrimitive() -> BSON.Primitive {
        switch self {
        case .ascending: return Int32(1)
        case .descending: return Int32(-1)
        case .custom(let value): return value
        }
    }
}

/// A Sort object specifies to MongoDB in what order certain Documents need to be ordered
///
/// This can be used in normal and aggregate queries
public struct Sort: ValueConvertible, ExpressibleByDictionaryLiteral {
    /// The underlying Document
    var document: Document
    
    /// Makes this Sort specification a Document
    ///
    /// Technically equal to `makeBSONPrimtive` with the main difference being that the correct type is already available without extraction
    public func makeDocument() -> Document {
        return document
    }

    /// Makes this Sort specification a BSONPrimtive.
    ///
    /// Useful for embedding in a Document
    public func makePrimitive() -> BSON.Primitive {
        return self.document
    }
    
    /// Helper to make mutating/reading sort specifications more accessible
    public subscript(key: String) -> SortOrder? {
        get {
            guard let value = self.document[key] else {
                return nil
            }
            
            switch value {
            case let bool as Bool:
                return bool ? .ascending : .descending
            case let spec as Int32:
                if spec == 1 {
                    return .ascending
                } else if spec == -1 {
                    return .descending
                }
                
                fallthrough
            default:
                return .custom(value)
            }
        }
        set {
            self.document[key] = newValue
        }
    }
    
    /// Initializes a Sort object from a Dictionary literal.
    ///
    /// The key in the Dictionary Literal is the key you want to have sorted.
    ///
    /// The value in the Dictionary Literal is the `SortOrder` you want to use.
    /// (Usually `SortOrder.ascending` or `SortOrder.descending`)
    public init(dictionaryLiteral elements: (String, SortOrder)...) {
        self.document = Document(dictionaryElements: elements.map {
            ($0.0, $0.1)
        })
    }
    
    /// Initializes a custom Sort object from a Document
    public init(_ document: Document) {
        self.document = document
    }
}

/// Joins two sorts
public func +(lhs: Sort, rhs: Sort) -> Sort {
    return Sort(lhs.makeDocument() + rhs.makeDocument())
}
