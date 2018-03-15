//
//  Extension.swift
//  CTServer
//
//  Created by 任玉祥 on 2017/9/7.
//
//

import Foundation
import PerfectHTTP
import COpenSSL

extension String {
    
    var length : Int {
        get {
            #if swift(>=4.0)
                return count
            #else
                return characters.count
            #endif
        }
    }
    
    
    func toInt() -> Int {
        guard let int = Int(self) else { return 0 }
        return int
    }
    
    func isNull() -> Bool {
        return self.length == 0
    }
    
    static func time() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
}

extension HTTPRequest {
    func param(_ name: String) -> String {
        guard let value = param(name: name, defaultValue: "") else { return "" }
        return value
    }
}



