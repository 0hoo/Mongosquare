//
//  ConnectionAction.swift
//  Mongosquare
//
//  Created by sean on 2020/01/12.
//  Copyright © 2020 0hoo. All rights reserved.
//

import Foundation
import ReSwift

enum ConnectionAction: Action {
    case connected(SquareConnection)
    case disconnected
}
