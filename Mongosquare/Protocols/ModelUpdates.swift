//
//  ModelUpdates.swift
//  Mongosquare
//
//  Created by Sean Park on 7/15/18.
//  Copyright © 2018 0hoo. All rights reserved.
//

import Foundation

protocol ModelSubscriber {
    var subscriptionKey: String { get }
}

extension ModelSubscriber {
    var subscriptionKey: String { return "" }
}

protocol SquareModel {
    var subscriptionKey: String { get }
}

extension SquareModel {
    var subscriptionKey: String { return "" }
}

final class SquareStore { // maybe we need to create separate instances which belong to each connection
    private static var connectionSubscribers: [String: ConnectionSubscriber] = [:]
    private static var databaseSubscribers: [String: DatabaseSubscriber] = [:]
    private static var collectionSubscribers: [String: CollectionSubscriber] = [:]
    private static var documentSubscribers: [String: DocumentSubscriber] = [:]
    
    private static func unregister(connectionSubscriber subscriber: ConnectionSubscriber, for model: SquareConnection?) {
        if let modelKey = model?.subscriptionKey {
            connectionSubscribers.removeValue(forKey: "\(modelKey)-\(subscriber.subscriptionKey)")
        } else {
            connectionSubscribers = connectionSubscribers.filter { $0.value.subscriptionKey != subscriber.subscriptionKey }
        }
    }
    
    private static func unregister(databaseSubscriber subscriber: DatabaseSubscriber, for model: SquareDatabase?) {
        if let modelKey = model?.subscriptionKey {
            databaseSubscribers.removeValue(forKey: "\(modelKey)-\(subscriber.subscriptionKey)")
        } else {
            databaseSubscribers = databaseSubscribers.filter { $0.value.subscriptionKey != subscriber.subscriptionKey }
        }
    }
    
    private static func unregister(collectionSubscriber subscriber: CollectionSubscriber, for model: SquareCollection?) {
        if let modelKey = model?.subscriptionKey {
            collectionSubscribers.removeValue(forKey: "\(modelKey)-\(subscriber.subscriptionKey)")
        } else {
            collectionSubscribers = collectionSubscribers.filter { $0.value.subscriptionKey != subscriber.subscriptionKey }
        }
    }
    
    private static func unregister(documentSubscriber subscriber: DocumentSubscriber, for model: SquareDocument?) {
        if let modelKey = model?.subscriptionKey {
            documentSubscribers.removeValue(forKey: "\(modelKey)-\(subscriber.subscriptionKey)")
        } else {
            documentSubscribers = documentSubscribers.filter { $0.value.subscriptionKey != subscriber.subscriptionKey }
        }
    }
    
    static func register(subscriber: ModelSubscriber, for model: SquareModel) {
        guard !model.subscriptionKey.isEmpty else { return } // cannot subscribe with empty subscription key 
        switch (subscriber, model) {
        case (let subscriber as ConnectionSubscriber, let model as SquareConnection):
            connectionSubscribers["\(model.subscriptionKey)-\(subscriber.subscriptionKey)"] = subscriber
        case (let subscriber as DatabaseSubscriber, let model as SquareDatabase):
            databaseSubscribers["\(model.subscriptionKey)-\(subscriber.subscriptionKey)"] = subscriber
        case (let subscriber as CollectionSubscriber, let model as SquareCollection):
            collectionSubscribers["\(model.subscriptionKey)-\(subscriber.subscriptionKey)"] = subscriber
        case (let subscriber as DocumentSubscriber, let model as SquareDocument):
            documentSubscribers["\(model.subscriptionKey)-\(subscriber.subscriptionKey)"] = subscriber
        default:
            break
        }
    }
    
    static func unregister(subscriber: ModelSubscriber, for model: SquareModel? = nil) {
        guard let model = model else { // when model is not specified, unsubscribe for all cases
            if let subscriber = subscriber as? ConnectionSubscriber {
                unregister(connectionSubscriber: subscriber, for: nil)
            }
            
            if let subscriber = subscriber as? DatabaseSubscriber {
                unregister(databaseSubscriber: subscriber, for: nil)
            }
            
            if let subscriber = subscriber as? CollectionSubscriber {
                unregister(collectionSubscriber: subscriber, for: nil)
            }
            
            if let subscriber = subscriber as? DocumentSubscriber {
                unregister(documentSubscriber: subscriber, for: nil)
            }
            return
        }
        
        switch (subscriber, model) {
        case (let subscriber as ConnectionSubscriber, let model as SquareConnection):
            unregister(connectionSubscriber: subscriber, for: model)
        case (let subscriber as DatabaseSubscriber, let model as SquareDatabase):
            unregister(databaseSubscriber: subscriber, for: model)
        case (let subscriber as CollectionSubscriber, let model as SquareCollection):
            unregister(collectionSubscriber: subscriber, for: model)
        case (let subscriber as DocumentSubscriber, let model as SquareDocument):
            unregister(documentSubscriber: subscriber, for: model)
        default:
            break
        }
    }
    
    // model update propagation
    static func modelUpdated(_ model: SquareModel, isSubtreeUpdated: Bool = false) {
        switch model {
        case let model as SquareConnection:
            connectionSubscribers.filter({ $0.key.hasPrefix(model.subscriptionKey)}).forEach {
                $0.value.didUpdate(connection: model, isSubtreeUpdated: isSubtreeUpdated)
            }
        case let model as SquareDatabase:
            databaseSubscribers.filter({ $0.key.hasPrefix(model.subscriptionKey)}).forEach {
                $0.value.didUpdate(database: model, isSubtreeUpdated: isSubtreeUpdated)
            }
        case let model as SquareCollection:
            collectionSubscribers.filter({ $0.key.hasPrefix(model.subscriptionKey)}).forEach {
                $0.value.didUpdate(collection: model, isSubtreeUpdated: isSubtreeUpdated)
            }
        case let model as SquareDocument:
            documentSubscribers.filter({ $0.key.hasPrefix(model.subscriptionKey)}).forEach {
                $0.value.didUpdate(document: model)
            }
        default:
            break
        }
    }
    
    init() {
        fatalError("Do not create any instances of SquareStore")
    }
}

protocol ConnectionSubscriber: ModelSubscriber {
    func didUpdate(connection: SquareConnection, isSubtreeUpdated: Bool)
}

protocol DatabaseSubscriber: ModelSubscriber {
    func didUpdate(database: SquareDatabase, isSubtreeUpdated: Bool)
}

protocol CollectionSubscriber: ModelSubscriber {
    func didUpdate(collection: SquareCollection, isSubtreeUpdated: Bool)
}

protocol DocumentSubscriber: ModelSubscriber {
    func didUpdate(document: SquareDocument)
}
