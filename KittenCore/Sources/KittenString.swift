import Foundation

/// A String simple type
///
/// Used to present multiple kind of strings which are all under the hood a series of bytes
///
/// Using KittenString/KittenBytes is useful to reduce String's overhead in places like parsers/serializers
public protocol KittenString {
    var kittenBytes: KittenBytes { get }
}

extension String : KittenString {
    /// Presents String's utf8 bytes as a KittenString type
    public var kittenBytes: KittenBytes {
        return KittenBytes([UInt8](self.utf8))
    }
}

extension StaticString : KittenString {
    /// Compares two staticstrings
    public static func ==(lhs: StaticString, rhs: StaticString) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    /// Gives staticstring a hashvalue
    public var hashValue: Int {
        return self.kittenBytes.hashValue
    }
    
    /// Represents this as a series of bytes (KittenBytes)
    public var kittenBytes: KittenBytes {
        var data = [UInt8](repeating: 0, count: self.utf8CodeUnitCount)
        memcpy(&data, self.utf8Start, data.count)
        
        return KittenBytes(data)
    }
}

public struct KittenBytes : Hashable, KittenString, SimpleConvertible, ExpressibleByStringLiteral, Comparable {
    /// Useful when sorting KittenBytes strings
    public static func <(lhs: KittenBytes, rhs: KittenBytes) -> Bool {
        for (position, byte) in lhs.bytes.enumerated() {
            guard position < rhs.bytes.count else {
                return true
            }
            
            if byte < rhs.bytes[position] {
                return true
            }
            
            if byte > rhs.bytes[position] {
                return false
            }
        }
        
        return String(bytes: lhs.bytes, encoding: .utf8)! > String(bytes: rhs.bytes, encoding: .utf8)!
    }
    
    /// Useful when sorting KittenBytes strings
    public static func >(lhs: KittenBytes, rhs: KittenBytes) -> Bool {
        for (position, byte) in lhs.bytes.enumerated() {
            guard position < rhs.bytes.count else {
                return false
            }
            
            if byte > rhs.bytes[position] {
                return true
            }
            
            if byte < rhs.bytes[position] {
                return false
            }
        }
        
        return String(bytes: lhs.bytes, encoding: .utf8)! > String(bytes: rhs.bytes, encoding: .utf8)!
    }
    
    /// Equates two KittenBytes
    public static func ==(lhs: KittenBytes, rhs: KittenBytes) -> Bool {
        return lhs.bytes == rhs.bytes
    }
    
    /// StringLiteral support
    public init(stringLiteral value: StaticString) {
        self.bytes = value.kittenBytes.bytes
    }
    
    /// StringLiteral support
    public init(unicodeScalarLiteral value: StaticString) {
        self.bytes = value.kittenBytes.bytes
    }
    
    /// StringLiteral support
    public init(extendedGraphemeClusterLiteral value: StaticString) {
        self.bytes = value.kittenBytes.bytes
    }
    
    /// Hashes KittenBytes
    public var hashValue: Int {
        guard bytes.count > 0 else {
            return 0
        }
        
        var h = 0
        
        for i in 0..<bytes.count {
            h = 31 &* h &+ numericCast(bytes[i])
        }
        
        return h
    }
    
    /// Converts KittenBytes to another String type
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if let string = String(bytes: bytes, encoding: .utf8) as? S {
            return string
        }
        
        return nil
    }
    
    /// The underlying bytes
    public let bytes: [UInt8]
    
    /// Converts this to itself
    public var kittenBytes: KittenBytes { return self }
    
    /// Initializes it from binary
    public init(_ data: [UInt8]) {
        self.bytes = data
    }
}
