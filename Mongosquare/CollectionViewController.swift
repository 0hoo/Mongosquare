//
//  CollectionViewController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 9/3/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa
import ExtendedJSON
import Cheetah
import MongoKitten

protocol DocumentSkippable {
    func reload(fieldsUpdated: Bool)
}

final class CollectionViewController: NSViewController {
    final class SkipLimit {
        var skip = 0
        var limit = 50
    }

    var skipLimit = SkipLimit()
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("CollectionViewController")
    }
    
    @IBOutlet var collectionView: NSView?
    
    var collection: SquareCollection? {
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
    
    var documents: [SquareDocument] {
        guard let collection = collection else { return [] }
       
        return collection.find(skipping: skipLimit.skip, limitedTo: skipLimit.limit)
    }
    
    var queriedDocuments: [SquareDocument] {
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
            if let queryString = queryOption.query, !queryString.isEmpty {
                query = Query(Document(try JSONObject(from: queryString)))
            }
            
            return collection?.find(query, sortedBy: sort, projecting: projection, skipping: skipLimit.skip, limitedTo: skipLimit.limit) ?? []
        } catch {
            print(error)
            return []
        }
    }
    
    var visibleFieldsKey: [String] {
        if queryOption.projectingFields.count > 0 {
            return queryOption.projectingFields
        } else {
            return queriedDocuments.max(by: { $0.keys.count < $1.keys.count })?.keys ?? queriedDocuments[0].keys
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
    
    func reload() {
        activeViewController?.reload(fieldsUpdated: true)
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
        
        let count = collection.count()
        if newSkip > count {
            return
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
        
        let count = collection.count()
        
        var limitToDisplay = skipLimit.skip + skipLimit.limit - 1
        limitToDisplay = min(limitToDisplay, count - 1)
        
        let label = "\(skipLimit.skip) - \(limitToDisplay) of \(count)"
        skipLimitSegmentedControl.setLabel(label, forSegment: 1)
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
    
    func deleteDocument() {
        if let document = outlineViewController?.selectedDocument, activeViewController == outlineViewController {
            delete(document: document)
        } else if let document = tableViewController?.selectedDocument, activeViewController == tableViewController {
            delete(document: document)
        }
    }
    
    func deleteKey() {
        if var document = outlineViewController?.selectedDocument, activeViewController == outlineViewController {
            if let key = outlineViewController?.selectedKey {
                document.removeValue(forKey: key)
                let _ = try? collection?.update(to: document)
                reload()
            }
        }
    }
    
    private func delete(document: SquareDocument) {
        let _ = try? collection?.collection.remove(Query(document.document), limitedTo: 1)
        reload()
        AppDelegate.shared.windowController.jsonViewController.documentDeleted()
    }
}

extension CollectionViewController: MMTabBarItem {
    
}
