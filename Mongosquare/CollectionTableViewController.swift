//
//  CollectionTableViewController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 9/3/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa
import MongoKitten

final class DocumentItem {
    let document: MongoKitten.Document
    
    init(document: MongoKitten.Document) {
        self.document = document
    }
}

final class CollectionTableViewController: NSViewController {
    override var nibName: String? {
        return "CollectionTableViewController"
    }
    
    @IBOutlet var tableView: NSTableView?
    
    weak var collectionViewController: CollectionViewController?

    fileprivate var items: [DocumentItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
     
        reload()
    }
}

extension CollectionTableViewController: DocumentSkippable {
    func reload() {
        guard let tableView = tableView else { return }
        guard let collectionViewController = collectionViewController else { return }
        
        while tableView.tableColumns.last != nil {
            if let last = tableView.tableColumns.last {
                tableView.removeTableColumn(last)
            }
        }
        
        if collectionViewController.documents.count == 0 {
            return
        }
        
        let document = collectionViewController.documents[0]
        for key in document.keys {
            let column = NSTableColumn(identifier: key)
            column.headerCell.stringValue = key
            tableView.addTableColumn(column)
        }
        items = collectionViewController.documents.map { DocumentItem(document: $0) }
        
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
            if key == tableColumn?.identifier {
                if let view = tableView.make(withIdentifier: "DocumentCellView", owner: self) as? NSTableCellView {
                    view.textField?.stringValue = "\(val)"
                    return view
                }
            }
        }
        return nil
    }
}

extension CollectionTableViewController: NSTableViewDelegate {
    
}
