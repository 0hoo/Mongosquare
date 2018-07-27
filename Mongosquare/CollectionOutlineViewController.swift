//
//  CollectionViewController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 8/31/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa
import ExtendedJSON
import Cheetah
import BSON

final class DocumentOutlineItem {
    var key: String
    let value: String
    let type: SquareDocument.ElementType
    var typeString: String {
        return type.description
    }
    var document: SquareDocument
    let isDocument: Bool
    var fields: [DocumentOutlineItem] = []
    var visibleFieldsKey: [String] = []
    
    init(key: String, value: String, type: SquareDocument.ElementType, document: SquareDocument, isDocument: Bool) {
        self.key = key
        self.value = value
        self.type = type
        self.document = document
        self.isDocument = isDocument
    }
    
    func fillFields() {
        if fields.count != 0 {
            return
        }
        for (key, val, type) in document {
            if let valueType = type {
                let fieldItem: DocumentOutlineItem
                if let subDocument = val as? SquareDocument {
                    let fields = "{ \(subDocument.keys.count) fields }"
                    fieldItem = DocumentOutlineItem(key: key, value: fields, type: valueType, document: subDocument, isDocument: true)
                } else {
                    fieldItem = DocumentOutlineItem(key: key, value: "\(val)", type: valueType, document: document, isDocument: false)
                }
                fields.append(fieldItem)
            }
        }
    }
}

final class CollectionOutlineViewController: NSViewController {
    override var nibName: NSNib.Name? {
        return NSNib.Name("CollectionOutlineViewController")
    }
    
    @IBOutlet var outlineView: NSOutlineView?

    weak var collectionViewController: CollectionViewController?

    private var items: [DocumentOutlineItem] = []
    
    var selectedDocument: SquareDocument? {
        guard let row = outlineView?.selectedRow, let item = outlineView?.item(atRow: row) as? DocumentOutlineItem else {
            return nil
        }
        return item.document
    }
    
    var selectedKey: String? {
        guard let row = outlineView?.selectedRow, let item = outlineView?.item(atRow: row) as? DocumentOutlineItem, !item.isDocument else {
            return nil
        }
        return item.key
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reload(fieldsUpdated: true)
        if let outlineView = outlineView, items.count > 0 {
            outlineView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: true)
            let _ = self.outlineView(outlineView, shouldSelectItem: items[0])
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(documentUpdated(_:)), name: SquareDocument.didUpdate, object: nil)
    }
    
    @objc func documentUpdated(_ notification: Notification) {
        guard let document = notification.object as? SquareDocument else { return }
        guard let documentId = ObjectId(document["_id"] as? Primitive) else { return }
        print("documentUpdated:\(document)")
        for item in items {
            if let oldId = ObjectId(item.document["_id"] as? Primitive), oldId == documentId {
                //item.document = document
            }
            for fieldItem in item.fields {
                if let oldId = ObjectId(item.document["_id"] as? Primitive), oldId == documentId {
                    //fieldItem.document = document
                }
            }
        }
    }
}

extension CollectionOutlineViewController: DocumentSkippable {
    func reload(fieldsUpdated: Bool) {
        guard let collectionViewController = collectionViewController else { return }
        
        items.removeAll()

        for (i, document) in collectionViewController.queriedDocuments.enumerated() {
            let fields = "\(document.keys.count) fields"
            let item = DocumentOutlineItem(key: "\(i + collectionViewController.skipLimit.skip)", value: fields, type: .document, document: document, isDocument: true)
            item.fillFields()
            items.append(item)
        }
        
        outlineView?.reloadData()
    }
}

extension CollectionOutlineViewController: NSOutlineViewDataSource {
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        guard let outlineView = outlineView else { return true }
        let row = outlineView.row(for: control)
        let column = outlineView.column(for: control)
        let valueToUpdate = fieldEditor.string
        guard let item = outlineView.item(atRow: row) as? DocumentOutlineItem else { return true }
        
        if column == 1 {
            if item.document.set(value: valueToUpdate, forKey: item.key, type: item.type) {
                print("set:\(item.document)")
                let updatedCount = collectionViewController?.collection?.update(item.document)
                fieldEditor.string = valueToUpdate
                print("value updated:\(String(describing: updatedCount))")
                print("send notification:\(item.document)")
                NotificationCenter.default.post(name: SquareDocument.didUpdate, object: item.document)
            } else {
                fieldEditor.string = item.value
            }
            return true
        } else if column == 0 {
            let keys = item.document.keys.filter { $0 != item.key }
            if keys.index(of: valueToUpdate) == nil {
                item.document[valueToUpdate] = item.document[item.key]
                item.document.removeValue(forKey: item.key)
                if let updatedCount = collectionViewController?.collection?.update(item.document), updatedCount > 0 {
                    item.key = valueToUpdate
                    fieldEditor.string = valueToUpdate
                    print("key updated:\(updatedCount))")
                } else {
                    fieldEditor.string = item.key
                }
            }
            return true
        }
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? DocumentOutlineItem, item.isDocument {
            return item.fields[index]
        }
        return items[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item as? DocumentOutlineItem, item.isDocument {
            if let collectionViewController = collectionViewController {
                item.visibleFieldsKey = collectionViewController.visibleFieldsKey
            }
            item.fillFields()
            return item.fields.count
        }
        return items.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let tableColumn = tableColumn else { return nil }
        guard let documentItem = item as? DocumentOutlineItem else { return nil }
        
        let view = outlineView.makeView(withIdentifier: tableColumn.identifier, owner: self) as! NSTableCellView
        view.textField?.delegate = self
        
        if tableColumn.identifier.rawValue == "DocumentColumnKey" {
            view.textField?.isEditable = documentItem.key != "_id"
            view.textField?.stringValue = documentItem.key
        } else if tableColumn.identifier.rawValue == "DocumentColumnValue" {
            view.textField?.isEditable = documentItem.key != "_id"
            view.textField?.stringValue = documentItem.value
        } else if tableColumn.identifier.rawValue == "DocumentColumnType" {
            view.textField?.isEditable = false
            view.textField?.stringValue = documentItem.typeString
        }
        
        if documentItem.type == .document {
            view.textField?.isEditable = false
        }
        
        return view
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let item = item as? DocumentOutlineItem {
            return item.isDocument
        }
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return false
    }
}

extension CollectionOutlineViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let item = item as? DocumentOutlineItem else { return false }
        AppDelegate.shared.windowController.didSelectDocument(collectionViewController: collectionViewController, document: item.document)
        return true
    }
}

extension CollectionOutlineViewController: NSTextFieldDelegate {
    
}
