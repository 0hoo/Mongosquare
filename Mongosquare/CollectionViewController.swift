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
            guard let collection = collection else { return }
            title = collection.name
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
    
    weak var windowController: WindowController?
    
    var outlineViewController: CollectionOutlineViewController?
    var tableViewController: CollectionTableViewController?
    var activeViewController: (NSViewController & DocumentSkippable)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        outlineViewController = CollectionOutlineViewController()
        outlineViewController?.collectionViewController = self
        tableViewController = CollectionTableViewController()
        tableViewController?.collectionViewController = self
        
        showOutlineViewController()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        updateWindowStatusBar()
    }
    
    @IBAction func segmentUpdated(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            showOutlineViewController()
        } else {
            showTableViewController()
        }
    }
    
    func previous() {
        if skipLimit.skip == 0 {
            return
        }
        
        skipLimit.skip = max(0, skipLimit.skip - skipLimit.limit)
        
        activeViewController?.reload()
        updateWindowStatusBar()
    }
    
    func next() {
        guard let collection = collection else { return }
        
        let newSkip = skipLimit.skip + skipLimit.limit
        do {
            let count = try collection.count()
            if newSkip > count {
                return
            }
        } catch {
            print(error)
        }

        skipLimit.skip = newSkip
        
        activeViewController?.reload()
        updateWindowStatusBar()
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
    
    private func updateWindowStatusBar() {
        updateSkipLimitSegmentedControl()
        updateCollectionViewModeSegmentedControl()
    }
    
    private func updateSkipLimitSegmentedControl() {
        guard let collection = collection else { return }
        guard let skipLimitSegmentedControl = windowController?.skipLimitSegmentedControl else { return }
        
        do {
            let count = try collection.count()
            
            var limitToDisplay = skipLimit.skip + skipLimit.limit - 1
            do {
                limitToDisplay = min(limitToDisplay, try collection.count() - 1)
            } catch {
                print(error)
            }
            
            let label = "\(skipLimit.skip) - \(limitToDisplay) of \(count)"
            skipLimitSegmentedControl.setLabel(label, forSegment: 1)
        } catch {
            print(error)
        }
    }
    
    private func updateCollectionViewModeSegmentedControl() {
        guard let collectionViewModeSegmentedControl = windowController?.collectionViewModeSegmentedControl else { return }

        if activeViewController == outlineViewController && collectionViewModeSegmentedControl.selectedSegment != 0 {
            collectionViewModeSegmentedControl.selectedSegment = 0
            windowController?.collectionViewModeChanged(collectionViewModeSegmentedControl)
        } else if activeViewController == tableViewController && collectionViewModeSegmentedControl.selectedSegment != 1 {
            collectionViewModeSegmentedControl.selectedSegment = 1
            windowController?.collectionViewModeChanged(collectionViewModeSegmentedControl)
        }
    }
}

extension CollectionViewController: MMTabBarItem {
    
}
