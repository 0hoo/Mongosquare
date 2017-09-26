//
//  CollectionViewController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 9/3/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa
import MongoKitten

final class CollectionViewController: NSViewController, MMTabBarItem {
    var hasCloseButton = true
    
    override var nibName: String? {
        return "CollectionViewController"
    }
    
    @IBOutlet var collectionView: NSView?
    
    var collection: MongoKitten.Collection? {
        didSet {
            title = collection?.name
            outlineViewController?.collection = collection
            tableViewController?.collection = collection
        }
    }
    
    var outlineViewController: CollectionOutlineViewController?
    var tableViewController: CollectionTableViewController?

    @IBAction func segmentUpdated(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            showOutlineViewController()
        } else {
            showTableViewController()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        outlineViewController = CollectionOutlineViewController()
        tableViewController = CollectionTableViewController()
        
        showOutlineViewController()
    }
    
    func showOutlineViewController() {
        if let subviews = collectionView?.subviews {
            subviews.forEach { $0.removeFromSuperview() }
        }
        
        outlineViewController?.collection = collection
        outlineViewController?.view.autoresizingMask = [.viewHeightSizable, .viewWidthSizable]
        if let view = outlineViewController?.view {
            view.frame = collectionView?.bounds ?? .zero
            collectionView?.addSubview(view)
        }
    }
    
    func showTableViewController() {
        if let subviews = collectionView?.subviews {
            subviews.forEach { $0.removeFromSuperview() }
        }
        
        tableViewController?.collection = collection
        tableViewController?.view.autoresizingMask = [.viewHeightSizable, .viewWidthSizable]
        if let view = tableViewController?.view {
            view.frame = collectionView?.bounds ?? .zero
            collectionView?.addSubview(view)
        }
    }
}
