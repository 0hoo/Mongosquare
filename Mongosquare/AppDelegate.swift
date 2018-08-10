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
        if let tabView = windowController.tabViewController.tabView {
            let viewControllers = (0..<tabView.numberOfTabViewItems).compactMap { tabView.tabViewItem(at: $0 ).viewController as? CollectionViewController }
            let keys = viewControllers.compactMap { $0.collection?.subscriptionKey }
            UserDefaults.standard.set(keys, forKey: kOpenedTabKeys)
            if let selectedTabViewItem = tabView.selectedTabViewItem {
                UserDefaults.standard.set(tabView.indexOfTabViewItem(selectedTabViewItem), forKey: kSelectedTabIndex)
            }
        }
    }
}
