import Dispatch

fileprivate let backgroundExecutionQueue = DispatchQueue(label: "org.openkitten.schrodinger.backgroundexecution", attributes: .concurrent)
fileprivate let futureManipulationQueue = DispatchQueue(label: "org.openkitten.schrodinger.futurequeue")

/// A promise that can be fulfilled manually
///
/// Can be awaited and can time out. Can throw an error or return the result.
public class ManualPromise<Wrapped> {
    /// The resulting value
    var result: Wrapped? = nil
    
    /// An error occurred
    var error: Swift.Error? = nil
    
    /// A semaphore
    let semaphore = DispatchSemaphore(value: 0)
    let timeout: DispatchTime
    
    /// Is true when the promise has been fulfilled with either an error or a result
    public var isCompleted: Bool {
        return result != nil || error != nil
    }
    
    /// Schrodinger errors
    public enum Error : Swift.Error, CustomStringConvertible {
        /// this must never happen
        case strangeInconsistency
        
        /// The promise has been completed twice. This may not occur
        case alreadyCompleted
        
        /// The promise completion has timed out
        case timeout(after: DispatchTime)
        
        /// Describes the error
        public var description: String {
            switch self {
            case .strangeInconsistency:
                return "Internal schrodinger error. Please file an issue"
            case .alreadyCompleted:
                return "You cannot complete a promise twice"
            case .timeout(let after):
                return "Timed out after \(after.rawValue)"
            }
        }
    }
    
    /// Creates a new promise providing a timeout
    public init(timeoutAfter interval: DispatchTimeInterval = .seconds(10)) {
        self.timeout = DispatchTime.now() + interval
    }
    
    /// Completes the promise with the wrapped value
    public func complete(_ value: Wrapped) throws {
        defer { semaphore.signal() }
        
        if result != nil || error != nil {
            error = Error.alreadyCompleted
            return
        }
        
        self.result = value
    }
    
    /// Fails the promise with an error
    public func fail(_ error: Swift.Error) throws {
        defer { semaphore.signal() }
        
        if result != nil || self.error != nil {
            self.error = Error.alreadyCompleted
            return
        }
        
        self.error = error
    }
    
    /// Waits for the promise to be fulfilled
    ///
    /// - returns: The promised value
    /// - throws: on timeout or error
    public func await<T>(_ closure: ((Wrapped) throws -> T)) throws -> T {
        guard semaphore.wait(timeout: timeout) == .success else {
            throw Error.timeout(after: timeout)
        }
        
        guard let result = result else {
            throw error ?? Error.strangeInconsistency
        }
        
        return try closure(result)
    }
    
    /// Waits for the promise to be fulfilled
    ///
    /// - returns: The promised value
    /// - throws: on timeout or error
    public func await() throws -> Wrapped {
        guard semaphore.wait(timeout: timeout) == .success else {
            throw Error.timeout(after: timeout)
        }
        
        guard let result = result else {
            throw error ?? Error.strangeInconsistency
        }
        
        return result
    }
}

/// A closure based promise that executes the closure in a DispatchQueue on a normal priority
public class Promise<Wrapped> : ManualPromise<Wrapped> {
    /// Completes the promise with the result of the closure
    func complete(_ closure: (() throws -> Wrapped)) {
        defer { semaphore.signal() }
        
        do {
            if result != nil || error != nil {
                error = Error.alreadyCompleted
                return
            }
            
            result = try closure() //.value(try closure())
        } catch {
            self.error = error
        }
    }
    
    /// Creates a new promise that can timeout
    ///
    /// Automatically executes the closure asynchronously
    public init(timeoutAfter interval: DispatchTimeInterval = .seconds(10), closure: @escaping (() throws -> Wrapped)) {
        super.init(timeoutAfter: interval)
        
        backgroundExecutionQueue.async {
            self.complete(closure)
        }
    }
}

/// A global async function that times creates a new promise
public func async<T>(timeoutAfter interval: DispatchTimeInterval = .seconds(10), _ closure: @escaping (() throws -> T)) -> Promise<T> {
    return Promise<T>(timeoutAfter: interval, closure: closure)
}
