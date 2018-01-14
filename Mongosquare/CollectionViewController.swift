//
//  CollectionViewController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 9/3/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa
import MongoKitten
import ExtendedJSON
import Cheetah

protocol DocumentSkippable {
    func reload(fieldsUpdated: Bool)
}

final class CollectionViewController: NSViewController {
    final class SkipLimit {
        var skip = 0
        var limit = 50
    }

    var skipLimit = SkipLimit()
    var didSelectDocument: ((MongoKitten.Document) -> ())? = { document in
        AppDelegate.shared.windowController.jsonViewController.document = document //.fragaria.setString("\(doc)")
    }
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("CollectionViewController")
    }
    
    @IBOutlet var collectionView: NSView?
    
    var collection: MongoKitten.Collection? {
        didSet {
            guard let collection = collection else { return }
            title = collection.name
        }
    }
    
    var queryOption: QueryOption = QueryOption() {
        didSet {
            outlineViewController?.reload(fieldsUpdated: true)
            tableViewController?.reload(fieldsUpdated: true)
            updateWindowStatusBar()
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
    
    var queriedDocuments: [Document] {
        do {
            var projection: Projection?
            if queryOption.projectingFields.count > 0 {
                projection = Projection(Document(dictionaryElements: queryOption.projectingFields.map {
                    return ($0, true)
                }).flattened())
            }
            
            var sort: Sort?
            if queryOption.sortingFields.count > 0 {
                sort = Sort(Document(dictionaryElements: queryOption.sortingFields.map {
                    return ($0.name, $0.ordering)
                }))
            }
            
            var query: Query? = nil
            if let queryString = queryOption.query {
                query = Query(Document(try JSONObject(from: queryString)))
            }
            
            guard let documents = try collection?.find(query, sortedBy: sort, projecting: projection, skipping: skipLimit.skip, limitedTo: skipLimit.limit) else { return [] }
            return documents.map { $0 }
        } catch {
            print(error)
            return []
        }
    }
    
    var visibleFieldsKey: [String] {
        if queryOption.projectingFields.count > 0 {
            return queryOption.projectingFields
        } else {
            return queriedDocuments[0].keys
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
        
        activeViewController?.reload(fieldsUpdated: false)
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
        
        activeViewController?.reload(fieldsUpdated: false)
        updateWindowStatusBar()
    }
    
    func showOutlineViewController() {
        if let subviews = collectionView?.subviews {
            subviews.forEach { $0.removeFromSuperview() }
        }
        
        activeViewController = outlineViewController
        outlineViewController?.view.autoresizingMask = [.height, .width]
        if let view = outlineViewController?.view {
            view.frame = collectionView?.bounds ?? .zero
            collectionView?.addSubview(view)
        }
        outlineViewController?.reload(fieldsUpdated: false)
    }
    
    func showTableViewController() {
        if let subviews = collectionView?.subviews {
            subviews.forEach { $0.removeFromSuperview() }
        }
        
        activeViewController = tableViewController
        tableViewController?.view.autoresizingMask = [.height, .width]
        if let view = tableViewController?.view {
            view.frame = collectionView?.bounds ?? .zero
            collectionView?.addSubview(view)
        }
        outlineViewController?.reload(fieldsUpdated: false)
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
