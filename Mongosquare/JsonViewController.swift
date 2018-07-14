//
//  JsonViewController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 1/12/18.
//  Copyright © 2018 0hoo. All rights reserved.
//

import Cocoa
import Cheetah
import WebKit

extension String {
    func javascriptEscaped() -> String {
        let str = self.replacingOccurrences(of: "\u{2028}", with: "\\u2028")
                        .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
        // Because escaping JavaScript is a non-trivial task (https://github.com/johnezang/JSONKit/blob/master/JSONKit.m#L1423)
        // we proceed to hax instead:
        let data = try! JSONSerialization.data(withJSONObject: [str], options: [])
        let encodedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)!
        return encodedString.substring(with: NSMakeRange(1, encodedString.length - 2))
    }
}

final class JsonViewController: NSViewController {

    @IBOutlet weak var webView: WebView!
    
    weak var collectionViewController: CollectionViewController?
    
    var document: SquareDocument? {
        didSet {
            guard let document = document else {
                return
            }
            var documentString = "\(document)"
            documentString = documentString.replacingOccurrences(of: "{", with: "{\n\t")
            documentString = documentString.replacingOccurrences(of: ",", with: ",\n\t")
            documentString = documentString.replacingOccurrences(of: "}", with: "\n}")
            documentString =  "\(documentString)".javascriptEscaped()
            let call = "editor.setValue(\(documentString))"
            let _ = webView?.stringByEvaluatingJavaScript(from: call)
            let _ = webView?.stringByEvaluatingJavaScript(from: "editor.focus()")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let path = Bundle.main.path(forResource: "editor", ofType: "html") {
            do {
                let content = try String(contentsOfFile: path)
                let resourcePath = Bundle.main.resourcePath!
                let baseURL = URL(fileURLWithPath: resourcePath + "/monaco/")
                webView?.mainFrame.loadHTMLString(content, baseURL: baseURL)
            } catch {
                print(error)
            }
        }
    }
    
    func save() {
//        do {
//            let updated = SquareDocument(document: Document(try JSONObject(from: fragaria.string())))
//            if updated["_id"] == nil {
//                let result = try collectionViewController?.collection?.insert(updated)
//                print("insert?: \(String(describing: result))")
//            } else {
//                let result = collectionViewController?.collection?.update(updated)
//                print("update?: \(String(describing: result))")
//            }
//            collectionViewController?.reload()
//        } catch {
//            print(error)
//        }
    }
    
    func newDocument() {
//        document = SquareDocument(document: Document())
//        fragaria.setString("")
    }
    
    func documentDeleted() {
//        document = nil
//        fragaria.setString("")
    }
}
