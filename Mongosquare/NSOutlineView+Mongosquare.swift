//
//  NSOutlineView+Mongosquare.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 4/18/18.
//  Copyright © 2018 0hoo. All rights reserved.
//

import Cocoa

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
