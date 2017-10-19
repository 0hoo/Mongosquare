//
//  QueryWindowController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 10/8/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa

struct QueryField {
    var name: String
    var type: String
    var ordering: Int?
    
    init(name: String, type: String, ordering: Int?) {
        self.name = name
        self.type = type
        self.ordering = ordering
    }
    
    init(name: String, type: String) {
        self.init(name: name, type: type, ordering: nil)
    }
}

final class SortTableViewDataSource: NSObject {
    var fields: [QueryField] = []
}

extension SortTableViewDataSource: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return fields.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
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
}

extension SortTableViewDataSource: NSTableViewDelegate {
    
}

final class QueryFieldsTableViewDataSource: NSObject {
    
    var didSetSelectedFields: (([QueryField]) -> Void)?
    var selectedRows = NSMutableOrderedSet()
    var fields: [QueryField] = []
    var selectedFields: [QueryField] = [] {
        didSet {
            didSetSelectedFields?(selectedFields)
        }
    }
}

extension QueryFieldsTableViewDataSource: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return fields.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
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
}

extension QueryFieldsTableViewDataSource: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        selectedRows.add(row)
        return true
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }
        
        let rowIndexes = tableView.selectedRowIndexes
        let rowsToDelete = selectedRows.flatMap { $0 as? Int }.filter { rowIndexes.contains($0) == false }
        for row in rowsToDelete {
            selectedRows.remove(row)
        }
        
        selectedFields = selectedRows.flatMap { $0 as? Int }.map { fields[$0] }
    }
}

final class QueryWindowController: NSWindowController {
    override var windowNibName: String? { return "QueryWindowController" }
    
    @IBOutlet weak var fieldsTableView: NSTableView?
    @IBOutlet weak var fieldsSegmentedControl: NSSegmentedControl?
    @IBOutlet weak var fieldsScanButton: NSButton?
    @IBOutlet weak var fieldsSearchField: NSSearchField?
    
    @IBOutlet weak var sortTableView: NSTableView?
    @IBOutlet weak var sortSearchField: NSSearchField?
    
    @IBOutlet var fieldsDataSource: QueryFieldsTableViewDataSource?
    @IBOutlet var sortDataSource: SortTableViewDataSource?
    
    weak var collectionViewController: CollectionViewController?
    
    var didSave: (([String]) -> Void)?
    
    var projectingFields: [String]? = nil {
        didSet {
            guard let dataSource = fieldsDataSource else { return }
            guard let projectingFields = projectingFields else { return }
            guard let fieldsTableView = fieldsTableView else { return }
            let selectedRows: [Int] = projectingFields.flatMap { projectingField in dataSource.fields.index(where: { projectingField == $0.name }) }
            if selectedRows.count > 0 {
                let indices: IndexSet = IndexSet(selectedRows)
                selectedRows.forEach { let _ = dataSource.tableView(fieldsTableView, shouldSelectRow: $0) }
                fieldsTableView.selectRowIndexes(indices, byExtendingSelection: false)
            }
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        let collectionName = collectionViewController?.collection?.fullName ?? ""
        window?.title = "Filter - \(collectionName)"

        fieldsSearchField?.delegate = self
        fieldsDataSource?.didSetSelectedFields = { [weak self] selectedFields in
            self?.fieldsSearchField?.stringValue = "{ " + selectedFields.map { "\"\($0.name): 1\"" }.joined(separator: ", ") + " }"
        }
        
        scan()
        projectingFields = collectionViewController?.projectingFields
    }
    
    func scan() {
        guard let collectionViewController = collectionViewController else { return }
        
        fieldsDataSource?.fields.removeAll()
        sortDataSource?.fields.removeAll()
        let document = collectionViewController.documents[0]
        for key in document.keys {
            let valueType = document.type(at: key)?.description ?? ""
            let queryField = QueryField(name: key, type: valueType)
            fieldsDataSource?.fields.append(queryField)
            sortDataSource?.fields.append(queryField)
        }
        fieldsTableView?.reloadData()
        sortTableView?.reloadData()
    }
    
    @IBAction func save(_ sender: NSButton) {
        guard let selectedFields = fieldsDataSource?.selectedFields else { return }
        close()
        didSave?(selectedFields.map { $0.name })
    }
    
    @IBAction func close(_ sender: NSButton) {
        close()
    }
}

extension QueryWindowController: NSSearchFieldDelegate {
    func searchFieldDidEndSearching(_ sender: NSSearchField) {
        fieldsDataSource?.selectedFields = []
        projectingFields = nil
        fieldsTableView?.deselectAll(self)
    }
}
