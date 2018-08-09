//
//  SquareDocument.swift
//  Mongosquare
//
//  Created by Sean Park on 3/12/18.
//  Copyright © 2018 0hoo. All rights reserved.
//

import Foundation
import Cheetah

typealias DocumentIndexIterationElement = (key: String, value: Any, type: SquareDocument.ElementType?)

struct SquareDocument: Swift.Collection, SquareModel {
    
    static let didUpdate = Notification.Name(rawValue: "SquareDocument.didUpdate")
    
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
    
    var isUnsavedDocument = false
    
    var collectionKey: String = ""
    var subscriptionKey: String {
        if let leafID = id {
            return "\(collectionKey)-\(leafID)"
        }
        return ""
    } 
    
    var document: Document
    var id: Primitive? {
        return self["_id"] as? Primitive
    }
    var idString: String? {
        return (self["_id"] as? ObjectId)?.hexString
    }
    
    var keys: [String] {
        return document.keys
    }
    
    init(document: Document) {
        self.document = document
    }
    
    init(string: String) throws {
        do {
            self.init(document: Document(try JSONObject(from: string)))
        } catch {
            print(error)
            throw error 
        }
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
    
    subscript(key: String) -> Any? {
        get {
            let element: Any? = document[key.components(separatedBy: ".")]
            if let element = element as? Document {
                return SquareDocument(document: element)
            }
            return element
        }
        set {
            if let value = newValue as? Primitive {
                document[key.components(separatedBy: ".")] = value
            }
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
        let element = document[position]
        var elementValue: Any = element.value
        if let value = elementValue as? Document {
            elementValue = SquareDocument(document: value)
        }
        
        return DocumentIndexIterationElement(key: element.key, value: elementValue, type: type(at: element.key))
    }
}

extension SquareDocument: CustomDebugStringConvertible {
    var debugDescription: String {
        let json = document.makeExtendedJSON()
        if let object = json as? JSONObject {
            return String(bytes: object.serialize(bringIDTop: true), encoding: .utf8) ?? ""
        }
        return json.serializedString()
    }
}
