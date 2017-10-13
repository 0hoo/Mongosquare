//
//  QueryWindowController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 10/8/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa

final class QueryWindowController: NSWindowController {
    override var windowNibName: String? { return "QueryWindowController" }
    
    @IBOutlet weak var fieldsTableView: NSTableView?
    @IBOutlet weak var fieldsSegmentedControl: NSSegmentedControl?
    @IBOutlet weak var fieldsSearchField: NSSearchField?
    @IBOutlet weak var fieldsScanButton: NSButton?
    
    weak var collectionViewController: CollectionViewController?
    
    var didSave: (([String]) -> Void)?

    typealias QueryField = (name: String, type: String)
    
    var selectedRows = NSMutableOrderedSet()
    
    var fields: [QueryField] = []
    var selectedFields: [QueryField] = [] {
        didSet {
            fieldsSearchField?.stringValue = "{ " + selectedFields.map { "\"\($0.name): 1\"" }.joined(separator: ", ") + " }"
        }
    }
    var projectingFields: [String]? = nil {
        didSet {
            guard let projectingFields = projectingFields else { return }
            guard let fieldsTableView = fieldsTableView else { return }
            let selectedRows: [Int] = projectingFields.flatMap { projectingField in fields.index(where: { projectingField == $0.name }) }
            if selectedRows.count > 0 {
                let indices: IndexSet = IndexSet(selectedRows)
                selectedRows.forEach { let _ = self.tableView(fieldsTableView, shouldSelectRow: $0) }
                fieldsTableView.selectRowIndexes(indices, byExtendingSelection: false)
            }
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        fieldsSearchField?.delegate = self
        
        let collectionName = collectionViewController?.collection?.fullName ?? ""
        window?.title = "Filter - \(collectionName)"
        
        scan()
        projectingFields = collectionViewController?.projectingFields
    }
    
    func scan() {
        guard let collectionViewController = collectionViewController else { return }
        
        fields.removeAll()
        let document = collectionViewController.documents[0]
        for key in document.keys {
            let valueType = document.type(at: key)?.description ?? ""
            fields.append((name: key, type: valueType))
        }
        fieldsTableView?.reloadData()
    }
    
    @IBAction func save(_ sender: NSButton) {
        close()
        didSave?(selectedFields.map { $0.name })
    }
    
    @IBAction func close(_ sender: NSButton) {
        close()
    }
}

extension QueryWindowController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == fieldsTableView {
            return fields.count
        }
        return 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView == fieldsTableView {
            guard let tableColumn = tableColumn else { return nil }

            let field = fields[row]
            let view = tableView.make(withIdentifier: tableColumn.identifier, owner: self) as! NSTableCellView
            if tableColumn.identifier == "DocumentColumnField" {
                view.textField?.stringValue = field.name
            } else if tableColumn.identifier == "DocumentColumnType" {
                view.textField?.stringValue = field.type
            }
            return view
        }

        return nil
    }
}

extension QueryWindowController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        selectedRows.add(row)
        return true
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let fieldsTableView = fieldsTableView else { return }
        let rowIndexes = fieldsTableView.selectedRowIndexes
        let rowsToDelete = selectedRows.flatMap { $0 as? Int }.filter { rowIndexes.contains($0) == false }
        for row in rowsToDelete {
            selectedRows.remove(row)
        }

        selectedFields = selectedRows.flatMap { $0 as? Int }.map { fields[$0] }
    }
}

extension QueryWindowController: NSSearchFieldDelegate {
    func searchFieldDidEndSearching(_ sender: NSSearchField) {
        selectedFields = []
        projectingFields = nil
        fieldsTableView?.deselectAll(self)
    }
}
