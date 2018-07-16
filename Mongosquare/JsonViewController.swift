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

final class JsonViewController: NSViewController {

    @IBOutlet weak var webView: WebView!
    
    weak var collectionViewController: CollectionViewController?
    
    var document: SquareDocument? {
        didSet {
            guard let document = document else {
                return
            }
            
            var documentString = "\(document)"
            documentString =  "\(documentString)".javascriptEscaped() ?? ""
            let call = "editor.setValue(\(documentString))"
            let _ = webView?.stringByEvaluatingJavaScript(from: call)
            let formatCall = "editor.getAction('editor.action.formatDocument').run()"
            let _ = webView?.stringByEvaluatingJavaScript(from: formatCall)
            if let oldDocument = oldValue {
                SquareStore.unregister(subscriber: self, for: oldDocument)
            }
            SquareStore.register(subscriber: self, for: document)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let path = Bundle.main.path(forResource: "editor", ofType: "html") {
            do {
                let content = try String(contentsOfFile: path)
                let resourcePath = Bundle.main.resourcePath!
                let baseURL = URL(fileURLWithPath: resourcePath + "/monaco/")
                webView?.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_2) AppleWebKit/604.4.7 (KHTML, like Gecko) Version/11.0.2 Safari/604.4.7"
                webView?.mainFrame.loadHTMLString(content, baseURL: baseURL)
                webView?.mainFrame.frameView?.allowsScrolling = false
            } catch {
                print(error)
            }
        }
    }
    
    func save() {
        guard let content = webView?.stringByEvaluatingJavaScript(from: "editor.getValue()") else { return }
        do {
            let updated = SquareDocument(document: Document(try JSONObject(from: content)))
            if updated["_id"] == nil {
                let result = try collectionViewController?.collection?.insert(updated)
                print("insert?: \(String(describing: result))")
            } else {
                let result = collectionViewController?.collection?.update(updated)
                print("update?: \(String(describing: result))")
            }
            collectionViewController?.reload()
        } catch {
            print(error)
        }
    }
    
    func newDocument() {
        document = SquareDocument(document: Document())
        let _ = webView?.stringByEvaluatingJavaScript(from: "editor.setValue('')")
    }
    
    func documentDeleted() {
        document = nil
        let _ = webView?.stringByEvaluatingJavaScript(from: "editor.setValue('')")
    }
    
    deinit {
        SquareStore.unregister(subscriber: self)
    }
}

extension JsonViewController: DocumentSubscriber {
    func didUpdate(document: SquareDocument) {
        self.document = document
    }
}
