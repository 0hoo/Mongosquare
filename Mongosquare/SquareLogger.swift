//
//  SquareLogger.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 8/15/18.
//  Copyright © 2018 0hoo. All rights reserved.
//

import Cocoa

final class SquareLogger: Logger {
    var usePrintLogging = true
    
    public init() {}
    
    public init(textView: NSTextView?) {
        self.textView = textView
    }
    
    var textView: NSTextView?
    
    func printLog(_ message: String) {
        if usePrintLogging {
            print(message)
        }
    }
    
    public func verbose(_ message: String) {
        printLog(message)
        textView?.append(message + "\n")
    }
    
    public func debug(_ message: String) {
        printLog(message)
        textView?.append(message + "\n")
    }
    
    public func info(_ message: String) {
        printLog(message)
        textView?.append(message + "\n")
    }
    
    public func warning(_ message: String) {
        printLog(message)
        textView?.append(message + "\n")
    }
    
    public func error(_ message: String) {
        printLog(message)
        textView?.append(message + "\n")
    }
    
    public func fatal(_ message: String) {
        printLog(message)
        textView?.append(message + "\n")
    }
}
