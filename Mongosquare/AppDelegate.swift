//
//  AppDelegate.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 8/31/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate {
        return NSApplication.shared.delegate as! AppDelegate
    }
    
    let windowController = WindowController()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        windowController.showWindow(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
}
