//
//  Tool.swift
//  CTServer
//
//  Created by 任玉祥 on 2017/11/13.
//

import Foundation

func EcodingString(data: Any) -> String {
    
    guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []) else {
        return "{\"message\":\"jsonDataEncodeError: line\(#line-1)\",\"status\":\"-1\"}"
    }
    
    guard let jsonString = String(data: jsonData, encoding: String.Encoding.utf8) else {
        return "{\"message\":\"jsonStringEncodeError: line\(#line-1)\",\"status\":\"-1\"}"
    }
    
    return jsonString
}

func CTLog<T>(_ message: T, fileName: String = #file, methodName: String = #function, lineNumber: Int = #line)
{
    #if os(Linux)
        let fName = fileName.components(separatedBy: "/").last ?? ""
        print("\(fName).\(methodName)[\(lineNumber)]: \(message)")
    #else
        print("\(message)")
    #endif
}
