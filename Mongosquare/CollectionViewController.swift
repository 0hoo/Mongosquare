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
    
    func deselectAll() {
        outlineViewController?.outlineView?.deselectAll(self)
        tableViewController?.tableView?.deselectAll(self)
    }
    
    var collection: SquareCollection? {
        didSet {
            guard let collection = collection else { return }
            title = collection.name
            
            if let oldCollection = oldValue {
                SquareStore.unregister(subscriber: self, for: oldCollection)
            }
            SquareStore.register(subscriber: self, for: collection)
        }
    }
    
    var queryOption: QueryOption = QueryOption() {
        didSet {
            reload()
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
            var keys = Array(Set<String>(queriedDocuments.reduce([String]()) { $0 + $1.keys }))
            if let idIndex = keys.index(of: "_id"), idIndex > 0 {
                keys.remove(at: idIndex)
                keys.insert("_id", at: 0)
            }
            return keys
        }
    }
    
    weak var windowController: WindowController?
    
    var outlineViewController: CollectionOutlineViewController?
    var tableViewController: CollectionTableViewController?
    var activeViewController: (NSViewController & DocumentSkippable)?
    
    func newDocument() -> SquareDocument {
        var doc = Document()
        var templateDocument: SquareDocument? = nil
        if queriedDocuments.count > 0 {
            templateDocument = queriedDocuments[0]
        }
        for key in visibleFieldsKey {
            if key == "_id" {
                continue
            }
            if let valueType = templateDocument?.type(at: key) {
                switch valueType {
                case .boolean:
                    doc[key] = false
                case .int32:
                    doc[key] = 0
                case .int64:
                    doc[key] = 0
                case .double:
                    doc[key] = 0.0
                default:
                    doc[key] = ""
                }
            } else {
                doc[key] = ""
            }
        }
        var document = SquareDocument(document: doc)
        document.isUnsavedDocument = true
        return document
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        outlineViewController = CollectionOutlineViewController()
        outlineViewController?.collectionViewController = self
        tableViewController = CollectionTableViewController()
        tableViewController?.collectionViewController = self
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()

        var limitChanged = false
        let limit = UserDefaults.standard.integer(forKey: UserDefaultKey.queryLimit)
        limitChanged = skipLimit.limit != limit
        if limit > 0 {
            skipLimit.limit = limit
        } else {
            skipLimit.limit = 50
        }
        
        updateWindowStatusBar()
        switchOutlineTableIfNeed()
        
        if limitChanged {
            reload()
        }
    }
    
    private func switchOutlineTableIfNeed() {
        guard let segmentedControl = windowController?.collectionViewModeSegmentedControl else { return }
        
        if segmentedControl.selectedSegment == 0 && activeViewController != outlineViewController {
            showOutlineViewController()
        } else if segmentedControl.selectedSegment == 1 && activeViewController != tableViewController {
            showTableViewController()
        }
    }
    
    @IBAction func segmentUpdated(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            showOutlineViewController()
        } else {
            showTableViewController()
        }
    }
    
    func reload(fieldsUpdated: Bool = false) {
        activeViewController?.reload(fieldsUpdated: fieldsUpdated)
        updateWindowStatusBar()
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
                let updated = collection?.update(document)
                print("deleteKey:\(String(describing: updated))")
                reload()
            }
        }
    }
    
    func nullToValue() {
        if var document = outlineViewController?.selectedDocument, activeViewController == outlineViewController {
            if let key = outlineViewController?.selectedKey {
                document[key] = NSNull()
                let updated = collection?.update(document)
                print("nullToValue: \(String(describing: updated))")
                reload()
            }
        }
    }
    
    private func delete(document: SquareDocument) {
        let _ = try? collection?.collection.remove(Query(document.document), limitedTo: 1)
        reload()
        AppDelegate.shared.windowController.jsonViewController.documentDeleted()
    }
    
    deinit {
        SquareStore.unregister(subscriber: self)
    }
}
extension CollectionViewController: CollectionSubscriber {
    
    var subscriptionKey: String {
        return "\(type(of: self))-\(ObjectIdentifier(self).hashValue)"
    }
    
    func didUpdate(collection: SquareCollection, updatedDocuments: [SquareDocument]?, updateType: ModelUpdateType) {
        if let updatedDocuments = updatedDocuments {
            switch updateType {
            case .inserted, .deleted:
                reload()
            case .updated:
                reload(fieldsUpdated: true)
            }
        } else {
            
        }
    }
}
extension CollectionViewController: MMTabBarItem {
    
}
