//
//  QueryTableCellView.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 12/8/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import AppKit

final class QueryTableCellView: NSTableCellView {
    @IBOutlet weak var fieldComboBox: NSComboBox!
    @IBOutlet weak var operationComboBox: NSComboBox!
    @IBOutlet weak var valueField: NSTextField!
    @IBOutlet weak var addButton: NSButton!
    
    override func awakeFromNib() {
        operationComboBox.isEditable = false
        operationComboBox.selectItem(at: 0)
    }
}
