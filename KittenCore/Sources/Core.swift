import Foundation

/// A type that is convertible to another DataType's supported type
public protocol Convertible {
    func convert<DT : DataType>(to type: DT.Type) -> DT.SupportedValue?
}

/// A data type
public protocol DataType {
    /// An object (dictionary-like) type
    associatedtype Object: InitializableObject
    
    /// A sequence type
    associatedtype Sequence: InitializableSequence
    
    /// All supported values, like bool, int, string or the above two
    associatedtype SupportedValue
}

/// A type that is convertible in a simple way
public protocol SimpleConvertible : Convertible {
    func convert<S: Any>(_ type: S.Type) -> S?
}

extension SimpleConvertible {
    /// Converts this to a type's supported value
    public func convert<DT>(to type: DT.Type) -> DT.SupportedValue? where DT : DataType {
        return self.convert(DT.SupportedValue.self)
    }
}

/// A sequence of `SupportedValue`. Useful for streams of data or something representable as a stream
///
/// Can be converted into an array using `Array(serializableSequence)
public protocol SerializableSequence : Convertible, Sequence {
    associatedtype SupportedValue
}

/// A Sequence that is initializable by another sequence
///
/// Initializable aren't a one-time stream
///
/// Can be converted into an array using `Array(initializableSequence)`
public protocol InitializableSequence : SerializableSequence {
    init<S: Sequence>(sequence: S) where S.Iterator.Element == SupportedValue
}


/// An object that is initializable by a stream of key-value pairs
///
/// Can represent itself as a dictionary
///
/// Initializable aren't a one-time stream
public protocol InitializableObject : InitializableSequence {
    /// The key type
    associatedtype ObjectKey: Hashable
    
    /// The value type
    associatedtype ObjectValue
    
    /// The supported key-value pair
    associatedtype SupportedValue = (ObjectKey, ObjectValue)
    
    /// The dictionary form of this type
    var dictionaryRepresentation: [ObjectKey: ObjectValue] { get }
}

extension InitializableObject {
    /// Converts this object to another datatype's object type
    public func convert<DT : DataType>(to type: DT.Type) -> DT.SupportedValue? {
        return self.convert(toObject: type) as? DT.SupportedValue
    }
    
    /// Converts this object to another object type
    public func convert<DT>(toObject type: DT.Type) -> DT.Object where DT : DataType {
        return DT.Object(sequence: self.dictionaryRepresentation.flatMap { key, value in
            let newKey: DT.Object.ObjectKey
            
            if let key = key as? DT.Object.ObjectKey {
                newKey = key
            } else if let key = key as? SimpleConvertible {
                if let key = key.convert(DT.Object.ObjectKey.self) {
                    newKey = key
                } else {
                    return nil
                }
            } else if let key = key as? Convertible {
                if let key = key.convert(to: type) as? DT.Object.ObjectKey {
                    newKey = key
                } else {
                    return nil
                }
            } else {
                return nil
            }
            
            let key = newKey
            
            if let value = value as? DT.Object.ObjectValue {
                return (key, value) as? DT.Object.SupportedValue
            } else if let value = value as? Convertible {
                if let value: DT.SupportedValue = value.convert(to: type) {
                    return (key, value) as? DT.Object.SupportedValue
                }
            }
            
            return nil
        })
    }
    
    /// Converts this object to a sequence type
    public func convert<DT>(toSequence type: DT.Type) -> DT.Sequence where DT : DataType {
        return DT.Sequence(sequence: self.dictionaryRepresentation.flatMap { _, value in
            if let value = value as? DT.Sequence.SupportedValue {
                return value
            } else if let value = value as? Convertible {
                if let value: DT.SupportedValue = value.convert(to: type) {
                    return value as? DT.Sequence.SupportedValue
                }
            }
            
            return nil
        })
    }
}

extension SerializableSequence {
    /// Converts this sequence to another type
    public func convert<DT>(to type: DT.Type) -> DT.SupportedValue? where DT : DataType {
        var iterator = self.makeIterator()
        
        return DT.Sequence(sequence: self.flatMap { value in
            if let value = iterator.next() {
                if let value = value as? DT.Sequence.SupportedValue {
                    return value
                } else if let value = value as? Convertible {
                    if let value: DT.SupportedValue = value.convert(to: type) {
                        return value as? DT.Sequence.SupportedValue
                    }
                }
            }
            
            return nil
        }) as? DT.SupportedValue
    }
}

/// Makes AnyIterator a sequence type
extension AnyIterator : SerializableSequence {
    /// Makes AnyIterator a sequence type
    public typealias SupportedValue = Any
}

/// Makes Dictionary a sequence type
extension Dictionary : InitializableObject {
    /// Makes Dictionary a sequence type
    public init<S>(sequence: S) where S : Sequence, S.Iterator.Element == (Key, Value) {
        var dict = [Key: Value]()
        
        for (key, value) in sequence {
            dict[key] = value
        }
        
        self = dict
    }
    
    /// Makes Dictionary a sequence of values
    public typealias SequenceType = Array<Value>
    
    /// Makes Dictionary representable as itself
    public var dictionaryRepresentation: [Key : Value] {
        return self
    }
}

/// Makes array an InitializableSequence
extension Array : InitializableSequence {
    /// Makes array an InitializableSequence
    public typealias SupportedValue = Element
    
    /// Initializes Array with a Sequence
    public init<S>(sequence: S) where S : Sequence, S.Iterator.Element == Element {
        self = Array(sequence)
    }
}

/// Converts String to another type
extension String : SimpleConvertible {
    /// Converts String to another type
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if let kittenBytes = self.kittenBytes as? S {
            return kittenBytes
        }
        
        if Double.self is S, let number = Double(self) as? S {
            return number
        }
        
        if Int.self is S, let number = Int(self) as? S {
            return number
        }
        
        if UInt.self is S, let number = UInt(self) as? S {
            return number
        }
        
        if UInt64.self is S, let number = UInt64(self) as? S {
            return number
        }
        
        if UInt32.self is S, let number = UInt32(self) as? S {
            return number
        }
        
        if UInt16.self is S, let number = UInt16(self) as? S {
            return number
        }
        
        if UInt8.self is S, let number = UInt8(self) as? S {
            return number
        }
        
        if Int64.self is S, let number = Int64(self) as? S {
            return number
        }
        
        if Int32.self is S, let number = Int32(self) as? S {
            return number
        }
        
        if Int16.self is S, let number = Int16(self) as? S {
            return number
        }
        
        if Int8.self is S, let number = Int8(self) as? S {
            return number
        }
        
        return nil
    }
}

/// Converts StaticString to another type
extension StaticString : SimpleConvertible {
    /// Converts StaticString to another type
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if let kittenBytes = self.kittenBytes as? S {
            return kittenBytes
        }
        
        if let string = String(self.unicodeScalar) as? S {
            return string
        }
        
        return nil
    }
}

/// Converts Bool as a convertible
extension Bool : SimpleConvertible {
    /// Converts Bool as a convertible
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        return nil
    }
}

/// Converts Data as a convertible
extension Data : SimpleConvertible {
    /// Converts Data as a convertible
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        return nil
    }
}

/// Converts NSRegularExpression as a Convertible
extension NSRegularExpression : SimpleConvertible {
    /// Converts NSRegularExpression as a Convertible
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        return nil
    }
}

/// Converts Null as a Convertible
extension NSNull : SimpleConvertible {
    /// Converts Null as a Convertible
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        return nil
    }
}

/// Null is NSNull
public typealias Null = NSNull
