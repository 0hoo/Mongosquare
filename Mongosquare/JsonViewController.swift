//
//  JsonViewController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 1/12/18.
//  Copyright © 2018 0hoo. All rights reserved.
//

import Cocoa
import ExtendedJSON
import MongoKitten

class JsonViewController: NSViewController {

    private let fragaria = MGSFragaria()
    
    weak var collectionViewController: CollectionViewController?
    
    var document: SquareDocument? {
        didSet {
            guard let document = document else {
                fragaria.setString("")
                return
            }
            var documentString = "\(document)"
            documentString = documentString.replacingOccurrences(of: "{", with: "{\n\t")
            documentString = documentString.replacingOccurrences(of: ",", with: ",\n\t")
            documentString = documentString.replacingOccurrences(of: "}", with: "\n}")
            fragaria.setString(documentString)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fragaria.setObject(self, forKey: MGSFODelegate)
        fragaria.embed(in: view)
        fragaria.setObject("JavaScript", forKey: MGSFOSyntaxDefinitionName)
    }
    
    func save() {
        do {
            let updated = SquareDocument(document: MongoKitten.Document(try JSONObject(from: fragaria.string())))
            if updated["_id"] == nil {
                let result = try collectionViewController?.collection?.insert(updated)
                print("insert?: \(String(describing: result))")
            } else {
                let result = try collectionViewController?.collection?.update(to: updated)
                print("update?: \(String(describing: result))")
            }
            collectionViewController?.reload()
        } catch {
            print(error)
        }
    }
    
    func newDocument() {
        document = SquareDocument(document: MongoKitten.Document())
        fragaria.setString("")
    }
}
