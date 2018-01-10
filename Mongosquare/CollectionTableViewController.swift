//
//  CollectionTableViewController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 9/3/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa
import MongoKitten

final class DocumentHeaderView: NSTableHeaderView {
}

final class DocumentItem {
    let document: MongoKitten.Document
    
    init(document: MongoKitten.Document) {
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
        for (key, val) in item.document {
            if key == tableColumn?.identifier.rawValue {
                if let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DocumentCellView"), owner: self) as? NSTableCellView {
                    if let subDocument = val as? Document {
                        view.textField?.stringValue = "{ \(subDocument.keys.count) fields }"
                    } else {
                        view.textField?.stringValue = "\(val)"
                    }
                    return view
                }
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

extension CollectionTableViewController: NSTableViewDelegate {
    
}
