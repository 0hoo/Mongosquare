//
//  CollectionViewController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 9/3/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa
import MongoKitten

protocol DocumentSkippable {
    func reload()
}

final class CollectionViewController: NSViewController {
    final class SkipLimit {
        var skip = 0
        var limit = 50
    }
    
    var skipLimit = SkipLimit()
    
    override var nibName: String? {
        return "CollectionViewController"
    }
    
    @IBOutlet var collectionView: NSView?
    
    var collection: MongoKitten.Collection? {
        didSet {
            title = collection?.name
        }
    }
    
    var documents: [Document] {
        do {
            guard let documents = try collection?.find(skipping: skipLimit.skip, limitedTo: skipLimit.limit) else { return [] }
            return documents.map { $0 }
        } catch {
            print(error)
            return []
        }
    }
    
    var outlineViewController: CollectionOutlineViewController?
    var tableViewController: CollectionTableViewController?
    var activeViewController: (NSViewController & DocumentSkippable)?

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
        outlineViewController?.collectionViewController = self
        tableViewController = CollectionTableViewController()
        tableViewController?.collectionViewController = self
        
        showOutlineViewController()
    }
    
    func previous() {
        if skipLimit.skip == 0 {
            return
        }
        
        skipLimit.skip = max(0, skipLimit.skip - skipLimit.limit)
        
        activeViewController?.reload()
    }
    
    func next() {
        skipLimit.skip += skipLimit.limit
        
        activeViewController?.reload()
    }
    
    func showOutlineViewController() {
        if let subviews = collectionView?.subviews {
            subviews.forEach { $0.removeFromSuperview() }
        }
        
        activeViewController = outlineViewController
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
        
        activeViewController = tableViewController
        tableViewController?.view.autoresizingMask = [.viewHeightSizable, .viewWidthSizable]
        if let view = tableViewController?.view {
            view.frame = collectionView?.bounds ?? .zero
            collectionView?.addSubview(view)
        }
    }
}

extension CollectionViewController: MMTabBarItem {
    
}
