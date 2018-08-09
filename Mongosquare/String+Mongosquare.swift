//
//  String+Mongosquare.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 8/9/18.
//  Copyright © 2018 0hoo. All rights reserved.
//

import Foundation

extension String {
    func javascriptEscaped() -> String? {
        let str = self.replacingOccurrences(of: "\u{2028}", with: "\\u2028")
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
        // Because escaping JavaScript is a non-trivial task (https://github.com/johnezang/JSONKit/blob/master/JSONKit.m#L1423)
        // we proceed to hax instead:
        if let data = try? JSONSerialization.data(withJSONObject: [str], options: []),
            let encodedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
            return encodedString.substring(with: NSMakeRange(1, encodedString.length - 2))
        }
        return nil
    }
}
