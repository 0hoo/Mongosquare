//
//  CollectionViewController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 8/31/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa
import MongoKitten

extension MongoKitten.ElementType: CustomStringConvertible {
    public var description : String {
        switch self {
            case .double: return "Double";
            case .string: return "String";
            case .document: return "Document";
            case .arrayDocument: return "Array Document";
            case .binary: return "Binary";
            case .objectId: return "objectId";
            case .boolean: return "Boolean";
            case .utcDateTime: return "Datetime";
            case .nullValue: return "null";
            case .regex: return "regex";
            case .javascriptCode: return "JavaScript code";
            case .javascriptCodeWithScope: return "JavaSCript code with Scope";
            case .int32: return "Int32";
            case .timestamp: return "Timestamp";
            case .int64: return "Int64";
            case .decimal128: return "Decimal";
            case .minKey: return "Min Key";
            case .maxKey: return "Max Key";
        }
    }
}

final class DocumentOutlineItem {
    let key: String
    let value: String
    let type: String
    let document: MongoKitten.Document
    let isDocument: Bool
    var fields: [DocumentOutlineItem] = []
    
    init(key: String, value: String, type: String, document: MongoKitten.Document, isDocument: Bool) {
        self.key = key
        self.value = value
        self.type = type
        self.document = document
        self.isDocument = isDocument
    }
    
    func fillFields() {
        if fields.count == 0 {
            for (key, val) in document {
                let valueType = document.type(at: key)?.description ?? ""
                let fieldItem: DocumentOutlineItem
                if let subDocument = val as? Document {
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
    override var nibName: String? {
        return "CollectionOutlineViewController"
    }
    
    @IBOutlet var outlineView: NSOutlineView?

    weak var collectionViewController: CollectionViewController?

    fileprivate var items: [DocumentOutlineItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reload()
    }
}

extension CollectionOutlineViewController: DocumentSkippable {
    func reload() {
        guard let collectionViewController = collectionViewController else { return }
        items.removeAll()
        
        for (i, document) in collectionViewController.documents.enumerated() {
            let fields = "{ \(document.keys.count) fields }"
            items.append(DocumentOutlineItem(key: "\(i + collectionViewController.skipLimit.skip)", value: fields, type: "Object", document: document, isDocument: true))
        }
        
        outlineView?.reloadData()
    }
}

extension CollectionOutlineViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? DocumentOutlineItem, item.isDocument {
            item.fillFields()
            return item.fields[index]
        }
        return items[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item as? DocumentOutlineItem, item.isDocument {
            item.fillFields()
            return item.fields.count
        }
        return items.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let tableColumn = tableColumn else { return nil }
        guard let documentItem = item as? DocumentOutlineItem else { return nil }
        
        let view = outlineView.make(withIdentifier: tableColumn.identifier, owner: self) as! NSTableCellView
        if tableColumn.identifier == "DocumentColumnKey" {
            view.textField?.stringValue = documentItem.key
        } else if tableColumn.identifier == "DocumentColumnValue" {
            view.textField?.stringValue = documentItem.value
        } else if tableColumn.identifier == "DocumentColumnType" {
            view.textField?.stringValue = documentItem.type
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
    
}
