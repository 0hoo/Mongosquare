//
//  InteractionView.swift
//  Mongosquare
//
//  Created by Sehyun Park on 12/2/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa

class InteractionView: NSView {
    var isEnabled: Bool = true
    
    override func mouseDown(with event: NSEvent) {
        if isEnabled {
            super.mouseDown(with: event)
        }
    }
}
