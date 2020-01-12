//
//  SquareLogger.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 8/15/18.
//  Copyright © 2018 0hoo. All rights reserved.
//

import Cocoa
import LoggerAPI
import Logging

final class SquareLogger: Logger {
    var usePrintLogging = true
    
    public init() {}
    
    public init(textView: NSTextView?) {
        self.textView = textView
        
    }
    
    var textView: NSTextView?
    
    func printLog(_ message: String, level: Logging.Logger.Level) {
        guard usePrintLogging else { return }
        
        switch level {
        case .trace:
            Log.verbose(message)
        case .debug:
            Log.debug(message)
        case .info, .notice:
            Log.info(message)
        case .warning:
            Log.info(message)
        case .error, .critical:
            Log.error(message)
        }
        
    }
    
    public func verbose(_ message: String) {
        printLog(message, level: .trace)
        textView?.append(message + "\n")
    }
    
    public func debug(_ message: String) {
        printLog(message, level: .debug)
        textView?.append(message + "\n")
    }
    
    public func info(_ message: String) {
        printLog(message, level: .info)
        textView?.append(message + "\n")
    }
    
    public func warning(_ message: String) {
        printLog(message, level: .warning)
        textView?.append(message + "\n")
    }
    
    public func error(_ message: String) {
        printLog(message, level: .error)
        textView?.append(message + "\n")
    }
    
    public func fatal(_ message: String) {
        printLog(message, level: .critical)
        textView?.append(message + "\n")
    }
}
