//
//  AppDelegate.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 8/31/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa
import MongoKitten

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate {
        return NSApplication.shared().delegate as! AppDelegate
    }
    
    let windowController = WindowController()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        /*
        do {
            let database = try MongoKitten.Database("mongodb://localhost/stockguide")
            let _ = database["stocks"]
        } catch {
            print(error)
        }
        */
        windowController.showWindow(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
}
