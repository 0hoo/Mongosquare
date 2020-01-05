//
//  CollectionTableViewController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 9/3/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa

final class DocumentHeaderView: NSTableHeaderView {
}

final class DocumentCellView: NSTableCellView {
    @IBOutlet weak var iconButton: NSButton!
    @IBOutlet weak var iconWidthConstraint: NSLayoutConstraint!
}

final class DocumentItem {
    var document: SquareDocument
    
    var types: [SquareDocument.ElementType] {
        return document.keys.compactMap { document.type(at: $0) }
    }
    
    init(document: SquareDocument) {
        self.document = document
    }
}

final class CollectionTableViewController: NSViewController {
    override var nibName: NSNib.Name? {
        return NSNib.Name("CollectionTableViewController")
    }
    
    @IBOutlet var tableView: NSTableView?
    
    weak var collectionViewController: CollectionViewController?

    fileprivate var items: [DocumentItem] = []
    
    var selectedDocument: SquareDocument? {
        guard let row = tableView?.selectedRow, items.count > row else { return nil }
        return items[row].document
    }

    override func viewDidLoad() {
        super.viewDidLoad()
     
        reload(fieldsUpdated: true)
    }
}

extension CollectionTableViewController: DocumentSkippable {
    func reload(fieldsUpdated: Bool) {
        guard let tableView = tableView else { return }
        guard let collectionViewController = collectionViewController else { return }
        
        let previousSelectedRow: Int = tableView.selectedRow
        
        if fieldsUpdated {
            while tableView.tableColumns.last != nil {
                if let last = tableView.tableColumns.last {
                    tableView.removeTableColumn(last)
                }
            }
            
            if collectionViewController.queriedDocuments.count == 0 {
                return
            }
            
            for key in collectionViewController.visibleFieldsKey {
                let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(key))
                column.headerCell.stringValue = key
                column.sortDescriptorPrototype = NSSortDescriptor(key: key, ascending: true)
                
                if let sortingField = collectionViewController.queryOption.sortingFields.first(where: {$0.name == key}) {
                    let arrow = sortingField.ordering == 1 ? "▲" : "▼"
                    column.title = "\(arrow) \(key)"
                }
                
                tableView.addTableColumn(column)
            }
            if let lastColumn = tableView.tableColumns.last {
                lastColumn.width += 100
            }
        }
        
        items = collectionViewController.queriedDocuments.map { DocumentItem(document: $0) }
        tableView.reloadData()
        tableView.selectRowIndexes(IndexSet(integer: previousSelectedRow), byExtendingSelection: false)
    }
}

extension CollectionTableViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = items[row]
        for (key, val, _) in item.document where key == tableColumn?.identifier.rawValue {
            if let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DocumentCellView"), owner: self) as? DocumentCellView {
                view.textField?.delegate = self
                view.textField?.isEditable = false
                if let subDocument = val as? SquareDocument {
                    view.textField?.stringValue = "{ \(subDocument.keys.count) fields }"
                } else {
                    if key == "_id" {
                        view.textField?.stringValue = primitiveOrEmpty(val).stripObjectId()
                        view.textField?.isEditable = false
                        view.iconWidthConstraint?.constant = 24
                    } else {
                        view.textField?.stringValue = primitiveOrEmpty(val)
                        view.textField?.isEditable = true
                        view.iconWidthConstraint?.constant = 0
                    }
                }
                return view
            }
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let queryOption = collectionViewController?.queryOption else { return }
        if tableView.sortDescriptors.count > 0 {
            var newQueryOption = queryOption
            if let key = tableView.sortDescriptors[0].key {
                var ordering: Int? = 1
                if let exist = queryOption.sortingFields.first(where: {$0.name == key}) {
                    if exist.ordering == 1 {
                        ordering = -1
                    } else if exist.ordering == -1 {
                        ordering = nil
                    }
                }
                newQueryOption.sortingFields.removeAll()
                newQueryOption.sortingFields.append(QueryField(name: key, ordering: ordering))
            }
            collectionViewController?.queryOption = newQueryOption
        }
        tableView.sortDescriptors = []
    }
}

extension CollectionTableViewController: NSControlTextEditingDelegate {
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        guard let tableView = tableView else { return true }
        let row = tableView.row(for: control)
        let column = tableView.column(for: control)
        let valueToUpdate = fieldEditor.string
        let item = items[row]
        let columnKey = item.document.keys[column]
        let tryUpdate = item.document.set(value: valueToUpdate, forKey: columnKey, type: item.types[column])
        if tryUpdate {
            try? collectionViewController?.collection?.update(item.document)
        }
        if let value = item.document[columnKey] {
            fieldEditor.string = "\(value)"
        }
        return true
    }
}

extension CollectionTableViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        let item = items[row]
        AppDelegate.shared.windowController.didSelectDocument(collectionViewController: collectionViewController, document: item.document)
        return true
    }
}

extension CollectionTableViewController: NSTextFieldDelegate {
    
}
