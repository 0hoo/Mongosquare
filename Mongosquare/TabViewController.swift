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
    override var nibName: NSNib.Name? {
        return NSNib.Name("TabViewController")
    }

    @IBOutlet weak var tabView: NSTabView?
    @IBOutlet weak var tabBar: MMTabBarView?
    @IBOutlet weak var tabHeightConstraint: NSLayoutConstraint?
    
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
        tabHeightConstraint?.constant = 0
    }
    
    func add(viewController: CollectionViewController) {
        adjustTabBarHeight()
        
        if let index = tabView?.tabViewItems.index(where: { ($0.viewController as? CollectionViewController)?.collection?.name == viewController.collection?.name }) {
            tabView?.selectTabViewItem(at: index)
        } else {
            let tabViewItem = NSTabViewItem(viewController: viewController)
            tabViewItem.hasCloseButton = true
            tabView?.addTabViewItem(tabViewItem)
            tabView?.selectTabViewItem(tabViewItem)
        }
    }
    
    private func adjustTabBarHeight(closing: Bool = false) {
        let countToHide = closing ? 1 : 0
        tabHeightConstraint?.constant = tabView?.numberOfTabViewItems == countToHide ? 0 : 25
        tabBar?.needsLayout = true
        tabBar?.layoutSubtreeIfNeeded()
    }
}

extension TabViewController: MMTabBarViewDelegate {
    func tabView(_ aTabView: NSTabView!, didClose tabViewItem: NSTabViewItem!) {
        adjustTabBarHeight(closing: true)
    }
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        guard let collectonViewController = tabViewItem?.viewController as? CollectionViewController else { return }
        didSelectViewController?(collectonViewController)
    }
}
