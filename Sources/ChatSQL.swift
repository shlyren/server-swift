//
//  ChatSQL.swift
//  CTServer
//
//  Created by 任玉祥 on 2017/10/26.
//

import Foundation


/// 保存未读消息 的数据库
class ChatSQL: ChatManager {
    
    
    override init() {
        super.init()
        guard connect() else { return }
        
        let sql = "CREATE TABLE IF NOT EXISTS t_chat_unread (id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT, userId TEXT, message MEDIUMTEXT)"
        
        if mySql.query(statement: sql) {
            CTLog("创建成功")
        }else{
            CTLog("创建失败: " + mySql.errorMessage())
        }
        
        closeConnect()
    }
    
    
    /// 保存数据
    ///
    /// - Parameters:
    ///   - data: 数据
    ///   - userId: userID
    func save(dataString: String, userId: String) {
        
        if userId.isNull() || dataString.isNull() { return }
        guard connect() else { return }
        
        let insert = "insert into t_chat_unread (userId, message) values ('\(userId)', '\(dataString)')"
        if mySql.query(statement: insert) == false {
            CTLog("插入失败: " + mySql.errorMessage())
        }
        closeConnect()
    }
    
    
    /// 获取数据
    ///
    /// - Parameter userId: uderId
    /// - Returns: 数据
    func getData(userId: String!) -> [Any] {
        
        if userId.isNull() { return [] }
        guard connect() else { return [] }
        
        let sql = "select * from t_chat_unread where userId = " + userId
        if mySql.query(statement: sql) == false {
            closeConnect()
            return []
        }
        
        guard let results = mySql.storeResults() else {
            closeConnect()
            return []
        }
        var res = [String]()
        results.forEachRow { (element) in
            if let data = element[2] {
               res.append(data)
            }
        }
        closeConnect()
        return res
    }
    
    
    /// 清空数据库
    ///
    /// - Parameter userId: userId
    func clearData(userId: String) {
        if userId.isNull() { return }
        guard connect() else { return }
        let sql = "delete from t_chat_unread where userId =" + userId
        if mySql.query(statement: sql) == false {
            CTLog("删除失败: " + mySql.errorMessage())
        }
        closeConnect()
    }
    
}
