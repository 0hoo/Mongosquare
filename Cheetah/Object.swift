//
//  Object.swift
//  Cheetah
//
//  Created by Joannis Orlandos on 18/02/2017.
//
//
import Foundation

public typealias CheetahValue = Value

/// A JSON object/dictionary type
public struct JSONObject : Value, ExpressibleByDictionaryLiteral, Equatable, Sequence {
    public init<S>(sequence: S) where S : Sequence, S.Iterator.Element == SupportedValue {
        for (key, value) in sequence {
            storage[key] = value
        }
    }
    
    public typealias SupportedValue = (String, CheetahValue)
    
    public var dictionaryRepresentation: [String : CheetahValue] {
        return storage
    }
    
    /// The dictionary representation
    internal var storage = [String: CheetahValue]()
    
    /// Initializes this Object from a JSON String
    public init(from data: String, allowingComments: Bool = true) throws {
        var parser = JSON(data.utf8, allowingComments: allowingComments)
        self = try parser.parse(rootLevel: true)
    }
    
    /// Initializes this Object from a JSON String as byte array
    public init(from data: [UInt8], allowingComments: Bool = true) throws {
        var parser = JSON(data, allowingComments: allowingComments)
        self = try parser.parse(rootLevel: true)
    }
    
    /// Initializes this Object from a JSON String as byte array
    public init(from data: Data, allowingComments: Bool = true) throws {
        var parser = JSON(data, allowingComments: allowingComments)
        self = try parser.parse(rootLevel: true)
    }
    
    /// Initializes this JSON Object with a Dictionary literal
    public init(dictionaryLiteral elements: (String, CheetahValue?)...) {
        for (key, value) in elements {
            self.storage[key] = value
        }
    }
    
    /// Initializes this Object from a dictionary
    public init(_ dictionary: [String: CheetahValue]) {
        self.storage = dictionary
    }
    
    /// The amount of key-value pairs in this object
    public var count: Int {
        return storage.count
    }
    
    /// Accesses a value in the JSON Object
    public subscript(_ key: String) -> CheetahValue? {
        get {
            return storage[key]
        }
        set {
            storage[key] = newValue
        }
    }
    
    /// Returns all keys in this object
    public var keys: [String] {
        return Array(storage.keys)
    }
    
    /// Returns all values in this object
    public var values: [CheetahValue] {
        return Array(storage.values)
    }
    
    /// Returns the dictionary representation of this Object
    public var dictionaryValue: [String: CheetahValue] {
        return storage
    }
    
    @discardableResult
    public mutating func removeValue(forKey key: String) -> CheetahValue? {
        return self.storage.removeValue(forKey: key)
    }
    
    /// Compares two Objects to see if all key-value pairs are equal
    public static func ==(lhs: JSONObject, rhs: JSONObject) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }
        
        for (key, value) in lhs {
            if let value = value as? String {
                guard let value2 = rhs[key] as? String else {
                    return false
                }
                
                guard value == value2 else {
                    return false
                }
                
            } else if let value = value as? Int {
                guard let value2 = rhs[key] as? Int else {
                    return false
                }
                
                guard value == value2 else {
                    return false
                }
                
            } else if let value = value as? Double {
                guard let value2 = rhs[key] as? Double else {
                    return false
                }
                
                guard value == value2 else {
                    return false
                }
                
            } else if let value = value as? JSONObject {
                guard let value2 = rhs[key] as? JSONObject else {
                    return false
                }
                
                guard value == value2 else {
                    return false
                }
                
            } else if let value = value as? JSONArray {
                guard let value2 = rhs[key] as? JSONArray else {
                    return false
                }
                
                guard value == value2 else {
                    return false
                }
                
            } else if value is NSNull {
                guard rhs[key] is NSNull else {
                    return false
                }
                
            } else if let value = value as? Bool {
                guard let value2 = rhs[key] as? Bool else {
                    return false
                }
                
                guard value == value2 else {
                    return false
                }
            }
        }
        
        return true
    }
    
    public func serialize() -> [UInt8] {
        return serialize(bringIDTop: false)
    }
    /// Serializes this JSON Object to a binary representation of the JSON text format
    public func serialize(bringIDTop: Bool) -> [UInt8] {
        var serializedData: [UInt8] = [SpecialCharacters.objectOpen]
        var arrayRepresentation: [SupportedValue] = storage.map { ($0, $1) }
        if bringIDTop, let idIndex = arrayRepresentation.index(where: { $0.0 == "_id"}) {
            let idObject = arrayRepresentation.remove(at: idIndex)
            arrayRepresentation.insert(idObject, at: 0)
        }
        
        for (position, pair) in arrayRepresentation.enumerated() {
            if position > 0 {
                serializedData.append(SpecialCharacters.comma)
            }
            
            serializedData.append(contentsOf: pair.0.serialize())
            serializedData.append(SpecialCharacters.colon)
            serializedData.append(contentsOf: pair.1.serialize())
        }
        
        return serializedData + [SpecialCharacters.objectClose]
    }
    
    /// Iterates over all key-value pairs
    public func makeIterator() -> DictionaryIterator<String, CheetahValue> {
        return storage.makeIterator()
    }
}
