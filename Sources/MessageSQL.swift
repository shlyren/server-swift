//
//  MessageSQL.swift
//  CTServer
//
//  Created by 任玉祥 on 2017/10/31.
//

import Foundation
import PerfectHTTP
import PerfectMySQL

class DiscoverMessageManager : DiscoverManager {
    override init() {
        super.init()
        guard connect() else { return }
        
        let sql = "CREATE TABLE IF NOT EXISTS t_topic_message (id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT, userId TEXT, topicId TEXT, commentId TEXT, message TEXT, content TEXT, fromId TEXT, fromName TEXT, type INT, isRead INT, time TEXT)"
        
        let success = mySql.query(statement: sql)
        if success {
            CTLog("创建成功")
        }else{
            CTLog("创建失败: " + mySql.errorMessage())
        }
        closeConnect()
    }
    
    func insert(userId: String,
                topicId: String,
                commentId: String,
                message: String,
                content: String,
                fromId: String,
                fromName: String,
                type: Int, // 0:全部, 1:评论, 2:回复, 3:艾特
                time: String) {
        
        guard connect() else {
            closeConnect()
            return
        }
        //userId TEXT, topicId TEXT, commentId TEXT, message TEXT, content TEXT fromId TEXT, fromName, TEXT, type INT, time TEXT
        let sql = "INSERT INTO t_topic_message (userId, topicId, commentId, message, content, fromId, fromName, type, isRead, time) VALUES (\(userId), '\(topicId)', '\(commentId)', '\(message)', '\(content)', '\(fromId)', '\(fromName)', '\(type)', '\(0)', '\(time)')"
        
        if mySql.query(statement: sql) {

            let token = loginSQLManager.getDeviceToken(userId: userId)
            let typeString = type == 0 ? "评论了你的动态" : "回复了你的评论"
            pushManager.pushDiscover(token: token,
                                     title: fromName+typeString,
                                     conent: message)
        } else{
            CTLog(mySql.errorMessage())
        }
        
        closeConnect()
        
    }
    
    func getMessage(request : HTTPRequest) -> ([[String:Any]]) {
        
        let messageId = request.param("messageId")
        let size = request.param(name: "size", defaultValue: "10")!
        let userId = request.param("userId")
        guard connect() else {
            return []
        }
        
        var sql = "select * from t_topic_message where userId = \(userId) "
        let type = request.param(name: "type", defaultValue: "0")?.toInt() ?? 0
        if type > 0 && type < 4 {
            sql += "and type = \(type) "
        }
        
        if messageId.toInt() > 0 {
            sql += "and id < \(messageId) order by time desc limit \(size)"
        } else{
            sql += "order by time desc limit \(size)"
        }
        
        var arr = [[String:Any]]()
        if mySql.query(statement: sql) {
            mySql.storeResults()?.forEachRow(callback: { (element) in
                arr.append(getMessageDict(element: element))
            })
        }else{
            CTLog(mySql.errorMessage())
        }
    
        closeConnect()
        return arr
    }
    
    
    func setMessageRead(request : HTTPRequest) -> (Bool, String) {
        let user = request.param("userId")
        if user.isNull() {
            return (false, "userId不能为空")
        }
        let id = request.param("messageId")
        if id.isNull() {
            return (false, "messageId不能为空")
        }
        guard connect() else {
            return (false, "数据库连接失败")
        }

        let sql = "update t_topic_message set isRead = 1 where userId = \(user) and id = \(id)"
        guard mySql.query(statement: sql) else {
            closeConnect()
            return (false, mySql.errorMessage())
        }
        closeConnect()
        return (true, "操作成功")
    }
}

private extension DiscoverMessageManager {
    
    func getMessageDict(element : [String?]) -> [String: Any] {
        var dict = [String:Any]()
        //id userId,topicId,commentId,message,content,fromId,fromName,type,time
        dict.updateValue(element[0] ?? "", forKey: "messageId")
        dict.updateValue(element[1] ?? "", forKey: "userId")
        dict.updateValue(element[2] ?? "", forKey: "topicId")
        dict.updateValue(element[3] ?? "", forKey: "commentId")
        dict.updateValue(element[4] ?? "", forKey: "message")
        dict.updateValue(element[5] ?? "", forKey: "content")
        dict.updateValue(element[6] ?? "", forKey: "fromId")
        dict.updateValue(element[7] ?? "", forKey: "fromName")
        dict.updateValue(Int(element[8] ?? "") ?? 0, forKey: "type")
        dict.updateValue(Bool(element[9] ?? "") ?? false, forKey: "isRead")
        dict.updateValue(element[10] ?? "", forKey: "time")
        return dict
    }
}
