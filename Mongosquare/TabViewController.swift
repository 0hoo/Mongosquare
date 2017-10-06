//
//  TabViewController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 9/5/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa

final class TabItem: NSObject, MMTabBarItem {
    var title: String = ""
    var viewController: CollectionViewController
    var hasCloseButton = true
    
    init(title: String, viewController: CollectionViewController) {
        self.title = title
        self.viewController = viewController
    }
}


final class TabViewController: NSViewController {
    static let tabHeight = CGFloat(26)
    
    override var nibName: String? {
        return "TabViewController"
    }

    @IBOutlet weak var tabView: NSTabView?
    @IBOutlet weak var tabBar: MMTabBarView?
    
    private var items: [TabItem] = []
    private var itemsByCollections: [String: TabItem] = [:]
    
    var didSelectViewController: ((CollectionViewController) -> Void)?
    
    var activeCollectionViewController: CollectionViewController? {
        return tabView?.selectedTabViewItem?.viewController as? CollectionViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar?.setStyleNamed("Yosemite")
        tabBar?.setOrientation(MMTabBarHorizontalOrientation)
        tabBar?.setButtonMinWidth(100)
        tabBar?.setButtonMaxWidth(280)
        tabBar?.setAllowsBackgroundTabClosing(true)
        tabBar?.setHideForSingleTab(true)
    }
    
    func add(viewController: CollectionViewController) {
        guard let collectionName = viewController.collection?.name else { return }
        
        if let item = itemsByCollections[collectionName], let index = items.index(where: { $0.title == item.title }) {
            tabView?.selectTabViewItem(at: index)
        } else {
            let tabItem = TabItem(title: collectionName, viewController: viewController)
            items.append(tabItem)
            itemsByCollections[collectionName] = tabItem

            let tabViewItem = NSTabViewItem(viewController: viewController)
            tabViewItem.hasCloseButton = true
            tabView?.addTabViewItem(tabViewItem)
            tabView?.selectTabViewItem(tabViewItem)
        }
    }
    
    fileprivate func show(tabItem: TabItem) {

    }
}

extension TabViewController: MMTabBarViewDelegate {
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        guard let collectonViewController = tabViewItem?.viewController as? CollectionViewController else { return }
        didSelectViewController?(collectonViewController)
    }
}
