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
            
            updateStatusView(document: document)

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
    
    func updateStatusView(document: SquareDocument) {
        //TODO: collectionViewController를 열지 않고 문서를 열 가능성이 있는지 확인 / 일단 없는 것으로 간주
        if let collection = collectionViewController?.collection {
            statusView.isHidden = false
            if collection.hostName.hasPrefix("mongodb://") {
                let serverName = collection.hostName
                connectionLabel.stringValue = String(serverName[serverName.index(serverName.startIndex, offsetBy: "mongodb://".count)...])
            } else {
                connectionLabel.stringValue = collection.hostName
            }
            databaseLabel.stringValue = collection.databaseName
            
            if document.isUnsavedDocument == true {
                collectionLabel.stringValue = "\(collection.name) (New)"
            } else {
                collectionLabel.stringValue = collection.name
            }
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
            var updated = try SquareDocument(string: content)
            updated.isUnsavedDocument = false
            if updated["_id"] == nil {
                let result = try collectionViewController?.collection?.insert(updated)
                print("insert?: \(String(describing: result))")
                
            } else {
                let result = collectionViewController?.collection?.update(updated)
                print("update?: \(String(describing: result))")
            }
            updateStatusView(document: updated)
        } catch {
            print(error)
        }
    }
    
    func newDocument() {
        if let document = collectionViewController?.newDocument() {
            collectionViewController?.deselectAll()
            self.document = document
            AppDelegate.shared.windowController.window?.makeFirstResponder(webView)
        }
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
