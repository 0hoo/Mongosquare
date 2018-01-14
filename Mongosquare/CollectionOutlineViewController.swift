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
    var key: String
    let value: String
    let type: MongoKitten.ElementType
    var typeString: String {
        return type.description
    }
    var document: MongoKitten.Document
    let isDocument: Bool
    var fields: [DocumentOutlineItem] = []
    var visibleFieldsKey: [String] = []
    
    init(key: String, value: String, type: MongoKitten.ElementType, document: MongoKitten.Document, isDocument: Bool) {
        self.key = key
        self.value = value
        self.type = type
        self.document = document
        self.isDocument = isDocument
    }
    
    func fillFields() {
        if fields.count == 0 {
            if visibleFieldsKey.count > 0 {
                for key in visibleFieldsKey {
                    if let val = document[key], let valueType = document.type(at: key) {
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
            } else {
                for (key, val) in document {
                    if let valueType = document.type(at: key) {
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
    }
}

final class CollectionOutlineViewController: NSViewController {
    override var nibName: NSNib.Name? {
        return NSNib.Name("CollectionOutlineViewController")
    }
    
    @IBOutlet var outlineView: NSOutlineView?

    weak var collectionViewController: CollectionViewController?

    private var items: [DocumentOutlineItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reload(fieldsUpdated: true)
    }
}

extension CollectionOutlineViewController: DocumentSkippable {
    func reload(fieldsUpdated: Bool) {
        guard let collectionViewController = collectionViewController else { return }
        items.removeAll()
        
        for (i, document) in collectionViewController.queriedDocuments.enumerated() {
            let fields = "{ \(collectionViewController.visibleFieldsKey.count > 0 ? collectionViewController.visibleFieldsKey.count : document.keys.count) fields }"
            items.append(DocumentOutlineItem(key: "\(i + collectionViewController.skipLimit.skip)", value: fields, type: .document, document: document, isDocument: true))
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
            var tryUpdate = false
            switch item.type {
                case .double:
                    if let value = Double(valueToUpdate) {
                        item.document[item.key] = value
                        tryUpdate = true
                    }
                case .string:
                    item.document[item.key] = valueToUpdate
                    tryUpdate = true
                case .boolean:
                    if let value = Bool(valueToUpdate) {
                        let booleanPrimitive: Primitive = value
                        item.document[item.key] = booleanPrimitive
                        tryUpdate = true
                    }
                case .int32:
                    if let value = Int32(valueToUpdate) {
                        item.document[item.key] = value
                        tryUpdate = true
                    }
                case .int64:
                    if let value = Double(valueToUpdate) {
                        item.document[item.key] = value
                        tryUpdate = true
                    }
                default:
                    tryUpdate = false
            }
            
            if tryUpdate {
                if let updatedCount = (try? collectionViewController?.collection?.update(to: item.document)).flatMap({ $0 }), updatedCount > 0 {
                    print("value updated:\(updatedCount)")
                    return true
                }
            }
            fieldEditor.string = item.value
            return true
        } else if column == 0 {
            let keys = item.document.keys.filter { $0 != item.key }
            if keys.index(of: valueToUpdate) == nil {
                item.document[valueToUpdate] = item.document[item.key]
                if let updatedCount = (try? collectionViewController?.collection?.update(to: item.document)).flatMap({ $0 }), updatedCount > 0 {
                    print("key updated:\(updatedCount)")
                    item.document.removeValue(forKey: item.key)
                    item.key = valueToUpdate
                    let _ = try? collectionViewController?.collection?.update(to: item.document)
                    return true
                }
            }
            fieldEditor.string = item.key
            return true
        }
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? DocumentOutlineItem, item.isDocument {
            item.fillFields()
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
        collectionViewController?.didSelectDocument?(item.document)
        return true
    }
}

extension CollectionOutlineViewController: NSTextFieldDelegate {
    
}
