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

final class DocumentItem {
    var document: SquareDocument
    
    var types: [SquareDocument.ElementType] {
        return document.keys.flatMap { document.type(at: $0) }
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

    override func viewDidLoad() {
        super.viewDidLoad()
     
        reload(fieldsUpdated: true)
    }
}

extension CollectionTableViewController: DocumentSkippable {
    func reload(fieldsUpdated: Bool) {
        guard let tableView = tableView else { return }
        guard let collectionViewController = collectionViewController else { return }
        
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
    }
}

extension CollectionTableViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = items[row]
        for (key, val, _) in item.document where key == tableColumn?.identifier.rawValue {
            if let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DocumentCellView"), owner: self) as? NSTableCellView {
                view.textField?.delegate = self
                view.textField?.isEditable = false
                if let subDocument = val as? SquareDocument {
                    view.textField?.stringValue = "{ \(subDocument.keys.count) fields }"
                } else {
                    view.textField?.stringValue = "\(val)"
                    if key != "_id" {
                        view.textField?.isEditable = true
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
            if let updatedCount = (try? collectionViewController?.collection?.update(to: item.document)).flatMap({ $0 }), updatedCount > 0 {
                print("value updated:\(updatedCount)")
                return true
            }
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
