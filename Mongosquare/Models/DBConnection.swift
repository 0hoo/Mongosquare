//
//  DBConnection.swift
//  Mongosquare
//
//  Created by Sehyun Park on 12/2/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Foundation
import MongoKitten

struct DBConnection {
    var name: String
    let username: String
    let password: String
    let host: String
    var port: Int = 27017
    
    let databaseName: String?
    
    var server: Server?
    var databases: [Database]?
    
    init(name: String = "", username: String, password: String, host: String, port: Int, dbName: String?) {
        self.name = name
        self.username = username
        self.password = password
        self.host = host
        self.port = port
        self.databaseName = dbName
        
        //let authentication = MongoCredentials(username: username, password: password, database: dbName ?? "admin", authenticationMechanism: AuthenticationMechanism.SCRAM_SHA_1)
        
        //let clientSettings = ClientSettings(host: MongoHost(hostname:host, port:UInt16(port)), sslSettings: nil, credentials: authentication, maxConnectionsPerServer: 100)
        if let clientSettings = try? ClientSettings(host) {
            self.server = try? Server(clientSettings)
        }
    }
    
    mutating func connect() -> Bool {
        guard let server = server else { return false }
        if server.isConnected {
            return true
        }
        
        databases = try? server.getDatabases()
        return databases != nil
    }
}
