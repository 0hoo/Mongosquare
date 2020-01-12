//
//  ConnectionWindowController.swift
//  Mongosquare
//
//  Created by Sehyun Park on 11/28/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Cocoa
import ReSwift
import LoggerAPI

final class ConnectionWindowController: NSWindowController {

    @IBOutlet weak var indicator: NSProgressIndicator!
    @IBOutlet private weak var hostField: NSTextField!
    @IBOutlet private weak var usernameField: NSTextField!
    @IBOutlet private weak var passwordField: NSSecureTextField!
    @IBOutlet private weak var databaseField: NSTextField!
    @IBOutlet private weak var portField: NSTextField!
    @IBOutlet private weak var connectButton: NSButton!
    
    @IBOutlet weak var connectionView: InteractionView!
    
    var connection: SquareConnection?
    weak var parentWindow: NSWindow?
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        connectButton.isEnabled = false
        hostField.delegate = self
    }
    
    @IBAction private func connect(_ sender: Any) {
        // show progress
        indicator.isHidden = false
        connectionView.isEnabled = false
        connection = SquareConnection(username: usernameField.stringValue, password: passwordField.stringValue, host: hostField.stringValue, port: Int(portField.stringValue) ?? 27017, dbName: databaseField.stringValue)
        
        if let connection = connection, connection.connect() {
            mainStore.dispatch(ConnectionAction.connected(connection))
            if let window = window {
                parentWindow?.endSheet(window)
            }
        } else {
            Log.debug("connection failed.. do something")
        }
        
        indicator.isHidden = true
        connectionView.isEnabled = true 
    }
}

extension ConnectionWindowController: NSTextFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        let text = hostField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: text),
            url.scheme == "mongodb",
            url.host?.isEmpty == false else {
            connectButton.isEnabled = false
            return
        }
        connectButton.isEnabled = true
    }
}
