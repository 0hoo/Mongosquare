//
//  JsonViewController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 1/12/18.
//  Copyright © 2018 0hoo. All rights reserved.
//

import Cocoa

class JsonViewController: NSViewController {

    private let fragaria = MGSFragaria()
    
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
}
