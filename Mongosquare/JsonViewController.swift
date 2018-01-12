//
//  JsonViewController.swift
//  Mongosquare
//
//  Created by Kim Younghoo on 1/12/18.
//  Copyright © 2018 0hoo. All rights reserved.
//

import Cocoa

class JsonViewController: NSViewController {

    let fragaria = MGSFragaria()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fragaria.setObject(self, forKey: MGSFODelegate)
        fragaria.embed(in: view)
        fragaria.setString("// We don't need the future.")
        // Do view setup here.
    }
    
}
