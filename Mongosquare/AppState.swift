//
//  AppState.swift
//  Mongosquare
//
//  Created by sean on 2020/01/11.
//  Copyright © 2020 0hoo. All rights reserved.
//

import Foundation
import ReSwift

struct AppState: StateType {
    var connectionState: ConnectionState = ConnectionState()
}
