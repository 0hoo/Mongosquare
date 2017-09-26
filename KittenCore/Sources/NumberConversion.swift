import Foundation

/// Converts a signed integer to another (supported) signed integer type
func representSigned<I : SignedInteger, S>(_ i: I) -> S? {
    let largeInt = numericCast(i) as Int64
    
    if largeInt >= Int64(Int.min), largeInt <= Int64(Int.max), let value = (numericCast(largeInt) as Int) as? S {
        return value
    }
    
    if largeInt >= Int64(Int64.min), largeInt <= Int64(Int64.max), let value = (numericCast(largeInt) as Int64) as? S {
        return value
    }
    
    if largeInt >= Int64(Int32.min), largeInt <= Int64(Int32.max), let value = (numericCast(largeInt) as Int32) as? S {
        return value
    }
    
    if largeInt >= Int64(Int16.min), largeInt <= Int64(Int16.max), let value = (numericCast(largeInt) as Int16) as? S {
        return value
    }
    
    if largeInt >= Int64(Int8.min), largeInt <= Int64(Int8.max), let value = (numericCast(largeInt) as Int8) as? S {
        return value
    }
    
    return nil
}

/// Converts a unsigned integer to another (supported) unsigned integer type
func representUnsigned<I : UnsignedInteger, S>(_ i: I) -> S? {
    let largeInt = numericCast(i) as UInt64
    
    if largeInt <= UInt64(Int.max), let value = (numericCast(largeInt) as UInt) as? S {
        return value
    }
    
    if largeInt <= UInt64(Int64.max), let value = (numericCast(largeInt) as UInt64) as? S {
        return value
    }
    
    if largeInt <= UInt64(Int32.max), let value = (numericCast(largeInt) as UInt32) as? S {
        return value
    }
    
    if largeInt <= UInt64(Int16.max), let value = (numericCast(largeInt) as UInt16) as? S {
        return value
    }
    
    if largeInt <= UInt64(Int8.max), let value = (numericCast(largeInt) as UInt8) as? S {
        return value
    }
    
    return nil
}

/// Conforms as a convertible to avoid multiple conformances
extension Int : SimpleConvertible {
    /// Converts to another type
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if let new = representSigned(self) as S? {
            return new
        }
        if let value = Double(self) as? S {
            return value
        }
        
        if let value = self.description as? S {
            return value
        }
        
        return nil
    }
}

/// Conforms as a convertible to avoid multiple conformances
extension Int8 : SimpleConvertible {
    /// Converts to another type
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if let new = representSigned(self) as S? {
            return new
        }
        
        if let value = Double(self) as? S {
            return value
        }
        
        if let value = self.description as? S {
            return value
        }
        
        return nil
    }
}

/// Conforms as a convertible to avoid multiple conformances
extension Int16 : SimpleConvertible {
    /// Converts to another type
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if let new = representSigned(self) as S? {
            return new
        }
        
        if let value = Double(self) as? S {
            return value
        }
        
        if let value = self.description as? S {
            return value
        }
        
        return nil
    }
}

/// Conforms as a convertible to avoid multiple conformances
extension Int32 : SimpleConvertible {
    /// Converts to another type
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if let new = representSigned(self) as S? {
            return new
        }
        
        if let value = Double(self) as? S {
            return value
        }
        
        if let value = self.description as? S {
            return value
        }
        
        return nil
    }
}

/// Conforms as a convertible to avoid multiple conformances
extension Int64 : SimpleConvertible {
    /// Converts to another type
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if let new = representSigned(self) as S? {
            return new
        }
        
        if let value = Double(self) as? S {
            return value
        }
        
        if let value = self.description as? S {
            return value
        }
        
        return nil
    }
}

/// Conforms as a convertible to avoid multiple conformances
extension UInt : SimpleConvertible {
    /// Converts to another type
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if let new = representUnsigned(self) as S? {
            return new
        }
        
        if let value = Double(self) as? S {
            return value
        }
        
        if let value = self.description as? S {
            return value
        }
        
        return nil
    }
}

/// Conforms as a convertible to avoid multiple conformances
extension UInt8 : SimpleConvertible {
    /// Converts to another type
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if let new = representUnsigned(self) as S? {
            return new
        }
        
        if let value = Double(self) as? S {
            return value
        }
        
        if let value = self.description as? S {
            return value
        }
        
        return nil
    }
}

/// Conforms as a convertible to avoid multiple conformances
extension UInt16 : SimpleConvertible {
    /// Converts to another type
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if let new = representUnsigned(self) as S? {
            return new
        }
        
        if let value = Double(self) as? S {
            return value
        }
        
        if let value = self.description as? S {
            return value
        }
        
        return nil
    }
}

/// Conforms as a convertible to avoid multiple conformances
extension UInt32 : SimpleConvertible {
    /// Converts to another type
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if let new = representUnsigned(self) as S? {
            return new
        }
        
        if let value = Double(self) as? S {
            return value
        }
        
        if let value = self.description as? S {
            return value
        }
        
        return nil
    }
}

/// Conforms as a convertible to avoid multiple conformances
extension UInt64 : SimpleConvertible {
    /// Converts to another type
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if let new = representUnsigned(self) as S? {
            return new
        }
        
        if let value = Double(self) as? S {
            return value
        }
        
        if let value = self.description as? S {
            return value
        }
        
        return nil
    }
}

/// Conforms as a convertible to avoid multiple conformances
extension Date : SimpleConvertible {
    /// Converts to another type
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if let signedInteger = representSigned(Int(self.timeIntervalSince1970)) as S? {
            return signedInteger
        }
        
        if let value = self.timeIntervalSince1970 as? S {
            return value
        }
        
        if let value = self.description as? S {
            return value
        }
        
        return nil
    }
}

/// Conforms as a convertible to avoid multiple conformances
extension Double : SimpleConvertible {
    /// Converts to another type
    public func convert<S>(_ type: S.Type) -> S? {
        if self is S {
            return self as? S
        }
        
        if self > 0 {
            return representUnsigned(UInt(self))
        }
        
        if let value = self.description as? S {
            return value
        }
        
        return representSigned(Int(self))
    }
}
