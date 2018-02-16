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
    var database: MongoKitten.Database?
    
    init(title: String, isHeader: Bool = false, isDatabase: Bool = false, count: Int = 0) {
        self.title = title
        self.isHeader = isHeader
        self.isDatabase = isDatabase
        self.count = count
    }
}

final class OutlineViewController: NSViewController {
    override var nibName: NSNib.Name? {
        return NSNib.Name("OutlineViewController")
    }
    
    static let headerCellIdentifier = "HeaderCell"
    static let itemCellIdentifier = "ItemCell"
    
    @IBOutlet var outlineView: NSOutlineView?
    
    var didSelectCollection: ((MongoKitten.Collection) -> ())?

    fileprivate var items: [OutlineItem] = []

    private var databases: [Database] = []
    private var unsavedCollections: [MongoKitten.Collection] = []
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        reloadDatabases()
    }
    
    func reloadDatabases() {
        do  {
            let server = try Server("mongodb://ec2-18-219-64-54.us-east-2.compute.amazonaws.com")
            databases = try server.getDatabases()
        } catch {
            print(error)
        }
        
        reloadItems()
    }
    
    func reloadItems() {
        
        items.removeAll()
        let local = OutlineItem(title: "Local", isHeader: true, isDatabase: false, count: databases.count)
        items.append(local)
        databases.forEach { db in
            do {
                let collections = try db.listCollections()
                let databaseItem = OutlineItem(title: db.name, isHeader: false, isDatabase: true)
                databaseItem.database = db
                local.items.append(databaseItem)
                
                for collection in collections {
                    let collectionItem = OutlineItem(title: collection.name, isHeader: false, isDatabase: false)
                    collectionItem.collection = collection
                    databaseItem.items.append(collectionItem)
                    databaseItem.count += 1
                }
                
                for newCollection in unsavedCollections {
                    if newCollection.database.name == db.name {
                        let collectionItem = OutlineItem(title: newCollection.name, isHeader: false, isDatabase: false)
                        collectionItem.collection = newCollection
                        databaseItem.items.append(collectionItem)
                        databaseItem.count += 1
                    }
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
                if item.collection?.name == collection.name {
                    outlineView.selectItem(item, parentItem)
                    break
                }
            }
            
        } while stack.count > 0
    }
}

extension OutlineViewController {
    @IBAction func addDatabase(_ sender: NSMenuItem) {
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "Add Database"
        
        let input = NSTextField(frame: CGRect(x: 0, y: 0, width: 360, height: 24))
        input.placeholderString = "Enter database name here"
        alert.accessoryView = input
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            do  {
                let server = try Server("mongodb://ec2-18-219-64-54.us-east-2.compute.amazonaws.com")
                let newDatabase = MongoKitten.Database(named: input.stringValue, atServer: server)
                databases.append(newDatabase)
                reloadItems()
            } catch {
                print(error)
            }
        }
    }
    
    @IBAction func addCollection(_ sender: NSMenuItem) {
        guard let selectedRow = outlineView?.selectedRow else { return }
        guard let item = outlineView?.item(atRow: selectedRow) as? OutlineItem else { return }
        guard let database = item.database, item.isDatabase else { return }
        
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "Add Collection"
        
        let input = NSTextField(frame: CGRect(x: 0, y: 0, width: 360, height: 24))
        input.placeholderString = "Enter collection name here"
        alert.accessoryView = input
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let newCollection = database[input.stringValue]
            unsavedCollections.append(newCollection)
            reloadItems()
        }
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
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(OutlineViewController.headerCellIdentifier), owner: self) as! NSTableCellView
            view.textField?.stringValue = item.title
            return view
        } else {
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(OutlineViewController.itemCellIdentifier), owner: self) as! OutlineTableCellView
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
