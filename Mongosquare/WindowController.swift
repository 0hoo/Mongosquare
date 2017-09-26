//
//  WindowController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 8/31/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa

final class WindowController: NSWindowController {
    override var windowNibName: String? { return "WindowController" }
    
    @IBOutlet weak var splitWrapperView: NSView?
    @IBOutlet weak var collectionViewModeSegmentedControl: NSSegmentedControl?
    
    lazy var sidebarController: OutlineViewController = {
        let sidebarController = OutlineViewController()
        sidebarController.didSelectCollection = { collection in
            let collectionViewController = CollectionViewController()
            collectionViewController.collection = collection
            self.tabViewController.add(viewController: collectionViewController)
        }
        return sidebarController
    }()
    
    lazy var collectionOutlineViewController: CollectionOutlineViewController = {
        let collectionOutlineViewController = CollectionOutlineViewController()
        return collectionOutlineViewController
    }()
    
    lazy var collectionViewController: CollectionViewController = {
       let collectionViewController = CollectionViewController()
        return collectionViewController
    }()
    
    lazy var tabViewController: TabViewController = {
       let tabViewController = TabViewController()
        return tabViewController
    }()
    
    lazy var splitViewController: NSSplitViewController = {
        let splitViewController = NSSplitViewController()
        
        let sidebarSplitViewItem = NSSplitViewItem(sidebarWithViewController: self.sidebarController)
        sidebarSplitViewItem.holdingPriority = NSLayoutPriorityDefaultLow
        sidebarSplitViewItem.maximumThickness = 200
        splitViewController.addSplitViewItem(sidebarSplitViewItem)
        
        let contentSplitViewItem = NSSplitViewItem(viewController: self.tabViewController)
        splitViewController.addSplitViewItem(contentSplitViewItem)
        
        return splitViewController
    }()
    
    override func windowDidLoad() {
        super.windowDidLoad()

        guard let _ = window else {
            fatalError("`window` is expected to be non nil by this time.")
        }
        
        splitViewController.view.setFrameSize(splitWrapperView?.bounds.size ?? .zero)
        splitViewController.view.autoresizingMask = [.viewHeightSizable, .viewWidthSizable]
        splitWrapperView?.addSubview(splitViewController.view)
        
        if let collectionViewModeSegmentedControl = collectionViewModeSegmentedControl {
            collectionViewModeChanged(collectionViewModeSegmentedControl)
        }
    }
    
    @IBAction func collectionViewModeChanged(_ sender: NSSegmentedControl) {
        let unselected = sender.selectedSegment == 0 ? 1 : 0
        
        if let image = sender.image(forSegment: unselected) {
            sender.setImage(image.tinted(color: .darkGray), forSegment: unselected)
        }
        if let image = sender.image(forSegment: sender.selectedSegment) {
            sender.setImage(image.tinted(color: .white), forSegment: sender.selectedSegment)
        }
    }
    
    @IBAction func sample(_ sender: Any?) {
        
    }
}
