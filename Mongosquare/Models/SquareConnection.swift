//
//  SquareConnection.swift
//  Mongosquare
//
//  Created by Sehyun Park on 12/2/17.
//  Copyright © 2017 0hoo. All rights reserved.
//

import Foundation
import MongoKitten

final class SquareConnection: Codable, SquareModel {
    static var connectionPool: [SquareConnection] = []
    static var testConnection: SquareConnection = {
        let connection = SquareConnection(username: "", password: "", host: "mongodb://ec2-18-219-64-54.us-east-2.compute.amazonaws.com")
        return connection
    }()
    
    static var localConnection: SquareConnection = {
        let connection = SquareConnection(username: "", password: "", host: "mongodb://localhost")
        return connection
    }()
    
    private static let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    
    var subscriptionKey: String {
        return "\(name),\(host):\(port)"
    }
    
    var name: String
    let username: String
    let password: String
    let host: String
    var port: Int = 27017
    
    let databaseName: String?
    
    var isFavorite: Bool = false
    var shouldAutoConnect: Bool = false
    
    let eventLoop: EventLoop
    var connection: MongoConnection?
    var databases: [SquareDatabase] = []
    
    init(name: String = "", username: String, password: String, host: String, port: Int = 27017, dbName: String? = nil) {
        self.name = name
        self.username = username
        self.password = password
        self.host = host
        self.port = port
        self.databaseName = dbName
        self.eventLoop = SquareConnection.eventGroup.next()
        
        //let authentication = MongoCredentials(username: username, password: password, database: dbName ?? "admin", authenticationMechanism: AuthenticationMechanism.SCRAM_SHA_1)
        
        //let clientSettings = ClientSettings(host: MongoHost(hostname:host, port:UInt16(port)), sslSettings: nil, credentials: authentication, maxConnectionsPerServer: 100)
        
        setup()
    }
    
    func setup() {
//        if let clientSettings = try? ClientSettings(host) {
//            self.server = try? Server(clientSettings)
//            self.server?.logger = AppDelegate.shared.windowController.makeLogger()
//        }
    }
    
    func connect() -> Bool {
        connection = try? MongoConnection.connect(settings: ConnectionSettings(host), on: self.eventLoop).wait()
        if connection == nil {
            return false
        }
        return reloadDatabases()
    }
   
    @discardableResult
    func reloadDatabases() -> Bool {
        guard let connection = connection else { return false }
        if let mongoDatabases = try? connection.listDatabases().wait() {
            databases = mongoDatabases.map { SquareDatabase(database: $0) }
        }
        return !databases.isEmpty
        //guard let server = server else { return false }
        
        //let kittenDatabases = (try? server.getDatabases()) ?? []
        //let unsaved = databases.filter { !$0.saved }
        //databases = kittenDatabases.map { SquareDatabase(database: $0) } + unsaved
    }
    
    @discardableResult
    func addDatabase(name: String) -> Bool {
//        guard let server = server else { return false }
//
//        let newDatabase = Database(named: name, atServer: server)
//        let squareDatabase = SquareDatabase(database: newDatabase, saved: false)
//        databases.append(squareDatabase)
//
//        SquareStore.modelUpdated(self, submodels: [squareDatabase], updateType: .inserted)
//        return true
        return true
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case username
        case password
        case host
        case port
        case databaseName
        case isFavorite
        case shouldAutoConnect
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try values.decode(String.self, forKey: .name)
        self.username = try values.decode(String.self, forKey: .username)
        self.password = try values.decode(String.self, forKey: .password)
        self.host = try values.decode(String.self, forKey: .host)
        self.port = try values.decode(Int.self, forKey: .port)
        self.databaseName = try values.decode(String.self, forKey: .databaseName)
        self.eventLoop = SquareConnection.eventGroup.next()
        
        setup()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(username, forKey: .username)
        try container.encode(password, forKey: .password)
        try container.encode(host, forKey: .host)
        try container.encode(port, forKey: .port)
        try container.encode(databaseName, forKey: .databaseName)
    }
}
