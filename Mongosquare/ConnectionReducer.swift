//
//  ConnectionReducer.swift
//  Mongosquare
//
//  Created by sean on 2020/01/12.
//  Copyright © 2020 0hoo. All rights reserved.
//

import Foundation
import ReSwift

func connectionReducer(action: ConnectionAction, state: ConnectionState) -> ConnectionState {
    var state = state
    switch action {
    case .connected(let connection):
        state.currentConnection = connection
    case .disconnected:
        state.currentConnection = nil
    }
    return state
}
