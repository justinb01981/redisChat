//
//  DemoUtils.swift
//  redisChat
//
//  Created by Justin Brady on 6/7/17.
//
//

import Foundation

class DebugLogger {
    
    enum LogLevel: Int {
        case debug = 0
        case warn = 1
        case error = 2
    }
    
    static func log(_ msg: String, with level: LogLevel) {
        print(msg)
    }
}
