//
//  NSTextView+Mongosquare.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 8/15/18.
//  Copyright © 2018 0hoo. All rights reserved.
//

import Cocoa

extension NSTextView {
    func append(_ string: String) {
        self.textStorage?.append(NSAttributedString(string: string))
        self.scrollToEndOfDocument(nil)
    }
}
