//
//  AppReducer.swift
//  Mongosquare
//
//  Created by sean on 2020/01/11.
//  Copyright © 2020 0hoo. All rights reserved.
//

import Foundation
import ReSwift

func appReducer(action: Action, state: AppState?) -> AppState {
    var state = state ?? AppState()
    switch action {
    case let action as ConnectionAction:
        state.connectionState = connectionReducer(action: action, state: state.connectionState)
    default:
        break
    }
    return state
}
