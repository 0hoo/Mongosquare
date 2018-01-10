//
//  NSImage+Mongosquare.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 9/14/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa

extension NSImage {
    func tinted(color: NSColor) -> NSImage {
        let size        = self.size
        let imageBounds = NSMakeRect(0, 0, size.width, size.height)
        let copiedImage = self.copy() as! NSImage
        
        copiedImage.lockFocus()
        color.set()
        __NSRectFillUsingOperation(imageBounds, .sourceAtop)
        copiedImage.unlockFocus()
        
        return copiedImage
    }
}
