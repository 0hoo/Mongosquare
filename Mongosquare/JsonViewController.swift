//
//  JsonViewController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 1/12/18.
//  Copyright © 2018 0hoo. All rights reserved.
//

import Cocoa
import WebKit

final class JsonViewController: NSViewController {
    
    @IBOutlet weak var webView: WebView!
    @IBOutlet weak var statusView: NSView!
    @IBOutlet weak var connectionLabel: NSTextField!
    @IBOutlet weak var databaseLabel: NSTextField!
    @IBOutlet weak var collectionLabel: NSTextField!
    
    weak var collectionViewController: CollectionViewController?
    
    var ignoreFocus = false
    
    var document: SquareDocument? {
        didSet {
            guard let document = document else {
                statusView.isHidden = true
                return
            }

            statusView.isHidden = false
            if let serverName = document.serverName {
                if serverName.hasPrefix("mongodb://") {
                    connectionLabel.stringValue = String(serverName[serverName.index(serverName.startIndex, offsetBy: "mongodb://".count)...])
                } else {
                    connectionLabel.stringValue = document.serverName ?? ""
                }
            }
            databaseLabel.stringValue = document.databaseName ?? ""
            collectionLabel.stringValue = document.collectionName ?? ""
            
            var documentString = "\(document)"
            documentString =  "\(documentString)".javascriptEscaped() ?? ""
            let call = "editor.setValue(\(documentString))"
            let _ = webView?.stringByEvaluatingJavaScript(from: call)
            ignoreFocus = true
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
        
        statusView.isHidden = true
        
        if let path = Bundle.main.path(forResource: "editor", ofType: "html") {
            do {
                let content = try String(contentsOfFile: path)
                let resourcePath = Bundle.main.resourcePath!
                let baseURL = URL(fileURLWithPath: resourcePath + "/monaco/")
                webView?.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_2) AppleWebKit/604.4.7 (KHTML, like Gecko) Version/11.0.2 Safari/604.4.7"
                webView?.mainFrame.loadHTMLString(content, baseURL: baseURL)
                webView?.mainFrame.frameView?.allowsScrolling = false
                webView?.uiDelegate = self
                webView.frameLoadDelegate = self
            } catch {
                print(error)
            }
        }
    }
    
    func save() {
        guard let content = webView?.stringByEvaluatingJavaScript(from: "editor.getValue()") else { return }
        do {
            let updated = try SquareDocument(string: content)
            if updated["_id"] == nil {
                
                let result = try collectionViewController?.collection?.insert(updated)
                print("insert?: \(String(describing: result))")
                
            } else {
                let result = collectionViewController?.collection?.update(updated)
                print("update?: \(String(describing: result))")
            }
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
    var subscriptionKey: String {
        return "\(type(of: self))-\(ObjectIdentifier(self).hashValue)"
    }

    func didUpdate(document: SquareDocument, updateType: ModelUpdateType) {
        // handle 
        self.document = document
    }
}

extension JsonViewController: WebUIDelegate {
    func webViewFocus(_ sender: WebView!) {
        print(sender)
    }
    
    func webView(_ sender: WebView!, makeFirstResponder responder: NSResponder!) {
        if ignoreFocus {
            ignoreFocus = false
        } else {
            AppDelegate.shared.windowController.window?.makeFirstResponder(webView)
        }
    }
}

extension JsonViewController: WebFrameLoadDelegate {
    func webView(_ sender: WebView!, didFinishLoadFor frame: WebFrame!) {
        let bridge = ScriptBridge()
        bridge.webView = webView
        webView.windowScriptObject.setValue(bridge, forKey: "bridge")
    }
}

class ScriptBridge: NSObject {
    weak var webView: WebView!
    
    @objc func focus() {
        if let webView = webView {
            AppDelegate.shared.windowController.window?.makeFirstResponder(webView)
        }
    }
    
    override class func isSelectorExcluded(fromWebScript selector: Selector!) -> Bool {
        return false
    }
}
