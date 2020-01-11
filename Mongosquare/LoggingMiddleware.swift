//
//  LoggingMiddleware.swift
//  Mongosquare
//
//  Created by sean on 2020/01/11.
//  Copyright © 2020 0hoo. All rights reserved.
//

import Foundation
import ReSwift
import LoggerAPI

func createLoggingMiddleware<State>() -> Middleware<State> {
    return { dispatch, getState in
        return { next in
            return { action in
                Log.debug("[Action] \(type(of: action)) \(action)")
                next(action)
            }
        }
    }
}
 
