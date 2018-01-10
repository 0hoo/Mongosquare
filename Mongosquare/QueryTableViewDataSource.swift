//
//  QueryTableViewDataSource.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 12/8/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import AppKit

final class QueryTableViewDataSource: NSObject {
    
}

extension QueryTableViewDataSource: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("QueryTableCellView"), owner: self) as! QueryTableCellView
        return view
    }
}

extension QueryTableViewDataSource: NSTableViewDelegate {
}
