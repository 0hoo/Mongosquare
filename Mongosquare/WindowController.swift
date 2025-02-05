//
//  WindowController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 8/31/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa
import ReSwift

class UserDefaultKey {
    static let openedTabKeys = "openedTabKeys"
    static let selectedTabIndex = "selectedTabIndex"
    static let queryLimit = "queryLimit"
}

func dialogOKCancel(question: String, text: String) -> Bool {
    let alert = NSAlert()
    alert.messageText = question
    alert.informativeText = text
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "Cancel")
    return alert.runModal() == .alertFirstButtonReturn
}

final class WindowController: NSWindowController, StoreSubscriber {
    typealias StoreSubscriberStateType = AppState
    
    override var windowNibName: NSNib.Name? { return NSNib.Name("WindowController") }
    
    @IBOutlet weak var splitWrapperView: NSView?
    @IBOutlet weak var collectionViewModeSegmentedControl: NSSegmentedControl?
    @IBOutlet weak var skipLimitSegmentedControl: NSSegmentedControl?
    @IBOutlet weak var logWindow: NSWindow?
    @IBOutlet weak var logTextView: NSTextView?
    
    var queryWindowController: QueryWindowController?
    var connectionWindowController: ConnectionWindowController?
    
    var loggers: [SquareLogger] = []
    
    func makeLogger() -> SquareLogger {
        let logger = SquareLogger(textView: logTextView)
        loggers.append(logger)
        return logger
    }
    
    lazy var sidebarController: OutlineViewController = {
        let sidebarController = OutlineViewController()
        sidebarController.didSelectCollection = { collection in
            let collectionViewController = CollectionViewController()
            collectionViewController.collection = collection
            collectionViewController.windowController = self
            self.tabViewController.add(viewController: collectionViewController)
        }
        return sidebarController
    }()
    
    lazy var tabViewController: TabViewController = {
       let tabViewController = TabViewController()
        tabViewController.didSelectViewController = { collectionViewController in
            self.jsonViewController.collectionViewController = collectionViewController
            if let collection = collectionViewController.collection {
                self.sidebarController.selectBy(collection)
            }
        }
        return tabViewController
    }()
    
    lazy var splitViewController: NSSplitViewController = {
        let splitViewController = NSSplitViewController()
        
        let sidebarSplitViewItem = NSSplitViewItem(sidebarWithViewController: self.sidebarController)
        sidebarSplitViewItem.holdingPriority = NSLayoutConstraint.Priority.defaultLow
        sidebarSplitViewItem.maximumThickness = 200
        splitViewController.addSplitViewItem(sidebarSplitViewItem)
        
        let contentSplitViewItem = NSSplitViewItem(viewController: self.tabViewController)
        splitViewController.addSplitViewItem(contentSplitViewItem)
        
        let jsonSplitViewItem = NSSplitViewItem(viewController: self.jsonViewController)
        splitViewController.addSplitViewItem(jsonSplitViewItem)
        
        return splitViewController
    }()
    
    lazy var jsonViewController: JsonViewController = {
        let jsonViewController = JsonViewController()
        return jsonViewController
    }()
    
    func didSelectDocument(collectionViewController: CollectionViewController?, document: SquareDocument) {
        jsonViewController.document = document
    }
        
    override func windowDidLoad() {
        super.windowDidLoad()

        guard let _ = window else {
            fatalError("`window` is expected to be non nil by this time.")
        }
        
        splitViewController.view.setFrameSize(splitWrapperView?.bounds.size ?? .zero)
        splitViewController.view.autoresizingMask = [.height, .width]
        splitWrapperView?.addSubview(splitViewController.view)
        
        if let collectionViewModeSegmentedControl = collectionViewModeSegmentedControl {
            collectionViewModeChanged(collectionViewModeSegmentedControl)
        }
        
        if let openedTabKeys = UserDefaults.standard.stringArray(forKey: UserDefaultKey.openedTabKeys) {
            for key in openedTabKeys {
                if let collection = self.sidebarController.findCollection(key) {
                    let collectionViewController = CollectionViewController()
                    collectionViewController.collection = collection
                    collectionViewController.windowController = self
                    self.tabViewController.add(viewController: collectionViewController)
                }
            }
            let selectedTabIndex = UserDefaults.standard.integer(forKey: UserDefaultKey.selectedTabIndex)
            if let tabView = tabViewController.tabView, tabView.tabViewItems.count > selectedTabIndex {
                tabView.selectTabViewItem(at: selectedTabIndex)
            }
        }
        
        showConnectionWindow()
        mainStore.subscribe(self)
    }
    
    func newState(state: AppState) {
        connection = state.connectionState.currentConnection
    }
    
    private var connection: SquareConnection? {
        didSet {
            guard let connection = connection, oldValue !== connection else {
                return
            }
        }
    }
    
    @IBAction func openLogs(_ sender: Any?) {
        logWindow?.makeKeyAndOrderFront(sender)
    }
    
    @IBAction func switchOutlineTableView(_ sender: Any?) {
        if let collectionViewModeSegmentedControl = collectionViewModeSegmentedControl {
            if collectionViewModeSegmentedControl.selectedSegment == 0 {
                collectionViewModeSegmentedControl.selectedSegment = 1
            } else {
                collectionViewModeSegmentedControl.selectedSegment = 0
            }
            collectionViewModeChanged(collectionViewModeSegmentedControl)
        }
    }
    
    @IBAction func collectionViewModeChanged(_ sender: NSSegmentedControl) {
//        let unselected = sender.selectedSegment == 0 ? 1 : 0
//
//        if let image = sender.image(forSegment: unselected) {
//            sender.setImage(image.tinted(color: .darkGray), forSegment: unselected)
//        }
//        if let image = sender.image(forSegment: sender.selectedSegment) {
//            sender.setImage(image.tinted(color: .white), forSegment: sender.selectedSegment)
//        }
        
        if sender.selectedSegment == 0 {
            self.tabViewController.activeCollectionViewController?.showOutlineViewController()
        } else {
            self.tabViewController.activeCollectionViewController?.showTableViewController()
        }
    }
    
    @IBAction func skipLimitedChanged(_ sender: NSSegmentedControl) {
        guard let window = self.window else { return }
        if sender.selectedSegment == 0 {
            self.tabViewController.activeCollectionViewController?.previous()
        } else if sender.selectedSegment == 1 {
            let alert = NSAlert()
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            alert.messageText = "Change Limit count"
            
            let input = NSTextField(frame: CGRect(x: 0, y: 0, width: 360, height: 24))
            input.placeholderString = "Limit"
            alert.accessoryView = input
            alert.beginSheetModal(for: window) { (response) in
                if response == .alertFirstButtonReturn {
                    if var limit = Int(input.stringValue) {
                        if limit == 0 {
                            limit = 50
                        }
                        UserDefaults.standard.set(limit, forKey: UserDefaultKey.queryLimit)
                        self.tabViewController.activeCollectionViewController?.skipLimit.limit = limit
                        self.tabViewController.activeCollectionViewController?.reload()
                    }
                }
            }
        } else if sender.selectedSegment == 2 {
            self.tabViewController.activeCollectionViewController?.next()
        }
    }
    
    @IBAction func showQueryWindow(_ sender: NSButton) {
        guard let collectionViewController = self.tabViewController.activeCollectionViewController else { return }
        queryWindowController = QueryWindowController()
        queryWindowController?.collectionViewController = collectionViewController
        queryWindowController?.didSave = { option in
            collectionViewController.queryOption = option
        }
        queryWindowController?.showWindow(self)
    }
    
    @IBAction func sample(_ sender: Any?) {
        
    }
    
    @IBAction func refreshCollection(_ sender: Any?) {
        self.tabViewController.activeCollectionViewController?.reload()
    }
    
    @IBAction func saveDocument(_ sender: Any?) {
        self.jsonViewController.save()
    }
    
    @IBAction func newDocument(_ sender: Any?) {
        self.jsonViewController.newDocument()
    }
    
    @IBAction func deleteDocument(_ sender: Any?) {
        if dialogOKCancel(question: "Delete this document?", text: "Are you sure to delete this document?") {
            self.tabViewController.activeCollectionViewController?.deleteDocument()
        }
    }
    
    @IBAction func deleteKey(_ sender: Any?) {
        self.tabViewController.activeCollectionViewController?.deleteKey()
    }
    
    @IBAction func nullToValue(_ sender: Any?) {
        self.tabViewController.activeCollectionViewController?.nullToValue()
    }
    
    @IBAction func nextTab(_ sender: Any?) {
        self.tabViewController.nextTab()
    }
    
    @IBAction func previousTab(_ sender: Any?) {
        self.tabViewController.previousTab()
    }
    
    @IBAction func closeTab(_ sender: Any?) {
        self.tabViewController.closeTab()
    }
    
    private func showConnectionWindow() {
        if connectionWindowController == nil {
            connectionWindowController = ConnectionWindowController(windowNibName: NSNib.Name("ConnectionWindowController"))
        }
        
        connectionWindowController?.parentWindow = window
        
        guard let connectionWindow = connectionWindowController?.window else { return }
        
        window?.beginSheet(connectionWindow, completionHandler: { (response) in
            
        })
    }
}
