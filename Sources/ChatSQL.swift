//
//  ChatSQL.swift
//  CTServer
//
//  Created by 任玉祥 on 2017/10/26.
//

import Foundation


/// 保存未读消息
class ChatSQL: ChatManager {
    
    
    /// 保存数据
    ///
    /// - Parameters:
    ///   - data: 数据
    ///   - userId: userID
    func save(data: String, userId: String) {
        
        if userId.isNull() || data.isNull() { return }
        guard connect() else { return }
        
        let sql = "create table if not exists t_chat_unread_\(userId) (id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT, data TEXT)"
        
        if mySql.query(statement: sql) {
            let insert = "insert into t_chat_unread_\(userId) (data) values ('\(data)')"
            if mySql.query(statement: insert) == false {
                CTLog("插入失败: " + mySql.errorMessage())
            }
        }else{
            CTLog("创建失败: " + mySql.errorMessage())
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
        
        let sql = "select * from t_chat_unread_" + userId
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
            if let data = element[1] {
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
        
        let sql = "delete from t_chat_unread_" + userId
        _ = mySql.query(statement: sql)
        closeConnect()
    }
    
}
