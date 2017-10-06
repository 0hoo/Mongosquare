//
//  OutlineViewController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 8/31/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa
import MongoKitten

extension NSOutlineView {
    func selectItem(_ item: Any?, _ parentItem: Any? = nil) {
        var index = self.row(forItem: item)
        if index < 0 {
            self.expandItem(parentItem)
            index = self.row(forItem: item)
            if index < 0 {
                return
            }
        }
        
        selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
    }
}

final class OutlineTableCellView: NSTableCellView {
    @IBOutlet weak var iconImageView: NSImageView?
    @IBOutlet weak var countField: NSTextField?
}

final class OutlineItem {
    let title: String
    let isHeader: Bool
    var count: Int
    var isDatabase: Bool
    var items: [OutlineItem] = []
    var collection: MongoKitten.Collection?
    
    init(title: String, _ isHeader: Bool = false, _ isDatabase: Bool = false, _ count: Int = 0) {
        self.title = title
        self.isHeader = isHeader
        self.isDatabase = isDatabase
        self.count = count
    }
}

final class OutlineViewController: NSViewController {
    override var nibName: String? {
        return "OutlineViewController"
    }
    
    static let headerCellIdentifier = "HeaderCell"
    static let itemCellIdentifier = "ItemCell"
    
    @IBOutlet var outlineView: NSOutlineView?
    
    var didSelectCollection: ((MongoKitten.Collection) -> ())?

    fileprivate var items: [OutlineItem] = []

    private var databases: [Database] = []
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        reload()
    }
    
    func reload() {
        do  {
            let server = try Server("mongodb://localhost")
            databases = try server.getDatabases()
        } catch {
            print(error)
        }
        
        items.removeAll()
        let local = OutlineItem(title: "Local", true, false, databases.count)
        items.append(local)
        databases.forEach { db in
            do {
                let collections = try db.listCollections()
                let databaseItem = OutlineItem(title: db.name, false, true)
                local.items.append(databaseItem)
                
                for collection in collections {
                    let collectionItem = OutlineItem(title: collection.name, false, false)
                    collectionItem.collection = collection
                    databaseItem.items.append(collectionItem)
                    databaseItem.count += 1
                }
            } catch {
                print(error)
            }
        }
        outlineView?.reloadData()
        outlineView?.expandItem(local, expandChildren: true)
    }
    
    func selectBy(_ collection: MongoKitten.Collection) {
        guard let outlineView = outlineView else { return }
        
        var currentItem: Any? = nil
        var parentItem: Any? = nil
        var stack: [OutlineItem] = []
        repeat {
            currentItem = stack.popLast()
            let numberOfChildren = self.outlineView(outlineView, numberOfChildrenOfItem: currentItem)
            var i = 0
            while i < numberOfChildren {
                parentItem = currentItem
                if let item = self.outlineView(outlineView, child: i, ofItem: currentItem) as? OutlineItem {
                    stack.append(item)
                }
                i += 1
            }
            
            if let item = currentItem as? OutlineItem {
                if let c = item.collection, c.name == collection.name {
                    outlineView.selectItem(item, parentItem)
                    break
                }
            }
            
        } while stack.count > 0
    }
}


extension OutlineViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? OutlineItem {
            return item.items[index]
        }
        return items[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item as? OutlineItem {
            return item.items.count
        }
        return items.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let item = item as? OutlineItem else { return nil }
        
        if item.isHeader {
            let view = outlineView.make(withIdentifier: OutlineViewController.headerCellIdentifier, owner: self) as! NSTableCellView
            view.textField?.stringValue = item.title
            return view
        } else {
            let view = outlineView.make(withIdentifier: OutlineViewController.itemCellIdentifier, owner: self) as! OutlineTableCellView
            view.textField?.stringValue = item.title
            view.iconImageView?.image = item.isDatabase ? #imageLiteral(resourceName: "icons8-database-blue"): #imageLiteral(resourceName: "icons8-document")
            if item.count > 0 {
                view.countField?.stringValue = "\(item.count)"
            } else {
                view.countField?.stringValue = ""
            }
            return view
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let item = item as? OutlineItem {
            return item.items.count > 0
        }
        return false
    }
}

extension OutlineViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let item = item as? OutlineItem else { return false }
        if !item.isHeader && !item.isDatabase {
            if let collection = item.collection {
                didSelectCollection?(collection)
            }
        }
        return true
    }
}
