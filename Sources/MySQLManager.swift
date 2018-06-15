//
//  MySQLManager.swift
//  CTServer
//
//  Created by 任玉祥 on 2017/9/8.
//
//

import Foundation
import PerfectLib
import PerfectMySQL

class MySQLManager {
    
    fileprivate let host = "106.14.9.43"
    fileprivate let user = "root"
    fileprivate let pwd = "123456"
    
    let mySql = MySQL()

    
    /// 连接数据库
    ///
    /// - Parameter name: 数据库名
    /// - Returns: 是否成功
    func connect(name: String) -> Bool {
        
        if mySql.connect(host: host, user: user, password: pwd) == false {
            if mySql.errorCode() != 2058 {
                CTLog("数据库连接失败: \(mySql.errorCode())  " + mySql.errorMessage())
                return false
            }
        }

        guard mySql.selectDatabase(named: name) else {
            Log.info(message: "数据库选择失败。错误代码：\(mySql.errorCode()) message：\(mySql.errorMessage())")
            return false
        }
        
        return true
    }
    
    
    /// 关闭连接
    func closeConnect() {
        //mySql.close()
        
    }
}

class DiscoverManager: MySQLManager {

    
    /// 连接discover数据库
    ///
    /// - Returns: 是否成功
    func connect() -> Bool {
        
        let flag = connect(name: "ct_discover")
        defer {
            closeConnect() //这个延后操作能够保证在程序结束时无论什么结果都会自动关闭数据库连接
        }
        return flag
    }
    
}


class ChatManager: MySQLManager {
    
    /// 连接聊天数据库
    ///
    /// - Returns: 是否成功
    func connect() -> Bool {
        
        let flag = connect(name: "ct_chat")
        defer {
            closeConnect() //这个延后操作能够保证在程序结束时无论什么结果都会自动关闭数据库连接
        }
        return flag
    }
}


class JiaQiManager: MySQLManager {
    
    /// 连接自用数据库, 用于测试等环境
    ///
    /// - Returns: 是否成功
    func connect() -> Bool {
        
        let flag = connect(name: "db_jiaqi")
        defer {
            closeConnect() //这个延后操作能够保证在程序结束时无论什么结果都会自动关闭数据库连接
        }
        return flag
    }
}





