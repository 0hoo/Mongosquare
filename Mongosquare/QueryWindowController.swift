//
//  QueryWindowController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 10/8/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa

struct QueryOption {
    var projectingFields: [String] = []
    var sortingFields: [QueryField] = []
    var query: String?
}

final class OrderingTableCellView: NSTableCellView {
    @IBOutlet weak var popUpButton: NSPopUpButton?
}

final class QueryField {
    var name: String
    var type: String?
    var ordering: Int?
    
    init(name: String, type: String?, ordering: Int?) {
        self.name = name
        self.type = type
        self.ordering = ordering
    }
    
    convenience init(name: String, type: String) {
        self.init(name: name, type: type, ordering: nil)
    }
    
    convenience init(name: String, ordering: Int?) {
        self.init(name: name, type: nil, ordering: ordering)
    }
}

final class SortTableViewDataSource: NSObject {
    var fields: [QueryField] = []
    
    func popUpButtonChanged(_ sender: NSPopUpButton) {
        let row = sender.tag
        let field = fields[row]
        if sender.selectedItem?.title == "-" {
            field.ordering = nil
        } else if sender.selectedItem?.title.lowercased() == "ascending" {
            field.ordering = 1
        } else if sender.selectedItem?.title.lowercased() == "descending" {
            field.ordering = -1
        }
    }
}

extension SortTableViewDataSource: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return fields.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn else { return nil }
        
        let field = fields[row]
        
        if tableColumn.identifier == "DocumentColumnOrdering" {
            let view = tableView.make(withIdentifier: "OrderingTableCellView", owner: self) as! OrderingTableCellView
            view.popUpButton?.tag = row
            view.popUpButton?.target = self
            view.popUpButton?.action = #selector(popUpButtonChanged(_:))
            if let ordering = field.ordering {
                view.popUpButton?.selectItem(withTag: ordering)
            }
            return view
        } else {
            let view = tableView.make(withIdentifier: tableColumn.identifier, owner: self) as! NSTableCellView
            if tableColumn.identifier == "DocumentColumnField" {
                view.textField?.stringValue = field.name
            } else if tableColumn.identifier == "DocumentColumnType" {
                view.textField?.stringValue = field.type ?? ""
            }
            return view
        }
    }
}

extension SortTableViewDataSource: NSTableViewDelegate {
    
}

final class FieldsTableViewDataSource: NSObject {
    
    var didSetSelectedFields: (([QueryField]) -> Void)?
    var selectedRows = NSMutableOrderedSet()
    var fields: [QueryField] = []
    var selectedFields: [QueryField] = [] {
        didSet {
            didSetSelectedFields?(selectedFields)
        }
    }
}

extension FieldsTableViewDataSource: NSTableViewDataSource {
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
            view.textField?.stringValue = field.type ?? ""
        }
        return view
    }
}

extension FieldsTableViewDataSource: NSTableViewDelegate {
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
    @IBOutlet weak var queryTextView: NSTextView?
    
    @IBOutlet var fieldsDataSource: FieldsTableViewDataSource?
    @IBOutlet var sortDataSource: SortTableViewDataSource?
    
    weak var collectionViewController: CollectionViewController?
    
    var didSave: ((QueryOption) -> Void)?
    
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
        
        queryTextView?.isAutomaticQuoteSubstitutionEnabled = false
        if let queryString = collectionViewController?.queryOption.query {
            queryTextView?.string = queryString
        }
        
        fieldsSearchField?.delegate = self
        fieldsDataSource?.didSetSelectedFields = { [weak self] selectedFields in
            self?.fieldsSearchField?.stringValue = "{ " + selectedFields.map { "\"\($0.name): 1\"" }.joined(separator: ", ") + " }"
        }
        
        scan()
        projectingFields = collectionViewController?.queryOption.projectingFields
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
            if let sortingField = collectionViewController.queryOption.sortingFields.first(where: { $0.name == queryField.name }) {
                queryField.ordering = sortingField.ordering
            }
        }
        fieldsTableView?.reloadData()
        sortTableView?.reloadData()
    }
    
    @IBAction func save(_ sender: NSButton) {
        guard let selectedFields = fieldsDataSource?.selectedFields else { return }
        guard let sortingFields = sortDataSource?.fields else { return }
        guard let queryString = queryTextView?.string else { return }
        
        let queryOption = QueryOption(projectingFields: selectedFields.map { $0.name }, sortingFields: sortingFields.filter {$0.ordering != nil }, query: queryString)
        didSave?(queryOption)
        close()
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
