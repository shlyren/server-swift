//
//  CommentSQL.swift
//  CTServer
//
//  Created by 任玉祥 on 2017/10/25.
//

import Foundation
import PerfectHTTP

/// 评论 数据
class DiscoverCommentManager: DiscoverManager {
    
    override init() {
        super.init()
        guard connect() else { return }
        
        let sql = "CREATE TABLE IF NOT EXISTS t_topic_comment (id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT, topicId TEXT, text TEXT, fromId TEXT, fromName TEXT, toId TEXT, toName TEXT, type INT, time TEXT)"
        
        let success = mySql.query(statement: sql)
        if success {
            CTLog("创建成功")
        }else{
            CTLog("创建失败: " + mySql.errorMessage())
        }
        
        closeConnect()
    }
    
    /// 插入评论
    func insertComment(request:HTTPRequest) -> (success:Bool, msg:String?) {
        
        let topicId = request.param("topicId")
        if topicId.isNull() {
            return (false, "topicId 不能为空")
        }
        guard postSQLManager.checkup(topicId: topicId) else {
            return (false, "该内容可能已被删除")
        }
        
        let text = request.param("text")
        if text.isNull() {
            return (false, "内容不能为空")
        }
        
        let fromId = request.param("fromId")
        
        let fromName = request.param("fromName")
        if fromId.isNull() || fromName.isNull() {
            return (false, "发送者不能为空")
        }
        let toId = request.param("toId")
        let toName = request.param("toName")
        let type = request.param("type").toInt()
        let time = String.time()
        
        guard connect() else {
            return (false, "操作失败")
        }
        //topicId TEXT, text TEXT, fromId TEXT, fromName TEXT, toId TEXT, toName TEXT, type INT, time TEXT
        let sql = "INSERT INTO t_topic_comment (topicId,text,fromId,fromName,toId,toName,type,time) VALUES (\(topicId), '\(text)', '\(fromId)', '\(fromName)', '\(toId)', '\(toName)', '\(type)', '\(time)')"
        
        let success = mySql.query(statement: sql)

        if success == true {
            CTLog("INSERT success")
            if fromId != toId {
                _ = mySql.query(statement: "select @@IDENTITY")
                let res = mySql.storeResults()?.next()
                let content = postSQLManager.getConetent(topicId: topicId)
                messageSQLManager.insert(userId: toId,
                                         topicId: topicId,
                                         commentId: res?[0] ?? "",
                                         message: text,
                                         content: content,
                                         fromId: fromId,
                                         fromName: fromName,
                                         type: 1,
                                         time: time)
                
            }
        }else {
            CTLog("INSERT error: " + mySql.errorMessage())
        }
        closeConnect()
        
        return (success, "")
    }
    
    
    /// 获取评论
    func getTopicComment(topicId: String?) -> [[String: Any]] {
        
        if topicId == nil { return [] }
        guard postSQLManager.checkup(topicId: topicId!) else {
            return []
        }
        
        guard connect() else { return [] }
        
        let sql = "select * from t_topic_comment where topicId = \(topicId!) order by time desc"
        if mySql.query(statement: sql) == false{
            closeConnect()
            return []
        }
        guard let results = mySql.storeResults() else {
            closeConnect()
            return []
        }
        
        var result = [[String: Any]]()
        results.forEachRow { (element) in
            
            let dict = self.getCommentDict(element: element)
            
            result.append(dict)
        }
        
        closeConnect()
        return result
    }
    
    func getCommentDetail(commendId:String) -> [String:Any]? {
        
        if commendId.isNull() {
            return nil
        }
        guard connect() else { return nil }
        
        let sql = "select * from t_topic_comment where id = \(commendId)"
        if mySql.query(statement: sql) == false{
            closeConnect()
            return nil
        }
        guard let results = mySql.storeResults() else {
            closeConnect()
            return nil
        }
        
        let element = results.next()

        closeConnect()
        if element == nil {
            return nil
        }
        return getCommentDict(element: element!)
        
    }
    
    func checkup(tpoicId: String!) -> Bool {
        
        if tpoicId.isNull() { return false }
        guard connect() else { return false }
        
        let sql = "select * from t_topic_comment where topicId = \(tpoicId!)"
        
        guard mySql.query(statement: sql) else {
            CTLog(mySql.errorMessage())
            closeConnect()
            return false
        }
        
        guard let results = mySql.storeResults() else { return false }
        
        return results.numRows() > 0
    }
    
}

private extension DiscoverCommentManager {
    func getCommentDict(element: [String?]) -> [String:Any] {
        var dict = [String:Any]()
        
        let commentId = element[0] ?? ""
        let topicId = element[1] ?? ""
        dict.updateValue(commentId as Any, forKey: "id")
        dict.updateValue(topicId as Any, forKey: "topicId")
        dict.updateValue(element[2] as Any, forKey: "text")
        
        var from = [String:Any]()
        from.updateValue(element[3] as Any, forKey: "id")
        from.updateValue(element[4] as Any, forKey: "name")
        dict.updateValue(from, forKey: "from")
        
        dict.updateValue(element[7] ?? 0, forKey: "type")
        dict.updateValue(element[8] as Any, forKey: "time")
        let replyscount = replyCommentSQLManager.getReplyCount(topicId: topicId, commentId: commentId)
        dict.updateValue(replyscount, forKey: "replyscount")
        
        return dict
    }
}


/// 评论回复
class DiscoverCommentReplyManager: DiscoverManager {
    override init() {
        super.init()
        guard connect() else { return }
        
        let sql = "CREATE TABLE IF NOT EXISTS t_topic_comment_reply (id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT, topicId TEXT,commentId TEXT, text TEXT, fromId TEXT, fromName TEXT, toId TEXT, toName TEXT, time TEXT)"
        
        let success = mySql.query(statement: sql)
        if success {
            CTLog("创建成功")
        }else{
            CTLog("创建失败: " + mySql.errorMessage())
        }
        
        closeConnect()
    }
    
    /// 获取楼中楼评论
    func getCommentReply(request: HTTPRequest) -> (Bool,Any?) {
        let topicId = request.param("topicId")
        if topicId.isNull() {
            return (false, "topicId 不能为空")
        }
        let commentId = request.param("commentId")
        if commentId.isNull() {
            return (false, "commentId 不能为空")
        }
        
        let sql = "select * from t_topic_comment_reply where topicId = \(topicId) and commentId = \(commentId) order by time desc"
        
        if mySql.query(statement: sql) == false{
            closeConnect()
            return (false, "数据库连接错误")
        }
        guard let results = mySql.storeResults() else {
            closeConnect()
            return (true, NSNull())
        }
        
        var result = [[String: Any]]()
        
        results.forEachRow { (elemt) in
            var dict = [String:Any]()
            //id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT, topicId TEXT,commnetId TEXT, text TEXT, fromId TEXT, fromName TEXT, toId TEXT, toName TEXT, time TEXT
            
            dict.updateValue(elemt[0] ?? "", forKey: "id")
            dict.updateValue(elemt[1] ?? "", forKey: "topicId")
            dict.updateValue(elemt[2] ?? "", forKey: "commentId")
            dict.updateValue(elemt[3] ?? "", forKey: "text")
            
            var from = [String : Any]()
            from.updateValue(elemt[4] ?? "", forKey: "id")
            from.updateValue(elemt[5] ?? "", forKey: "name")
            dict.updateValue(from, forKey: "from")
            
            
            if let toId = elemt[6], let toName = elemt[7] {
                var to = [String : String]()
                to.updateValue(toId, forKey: "id")
                to.updateValue(toName, forKey: "name")
                dict.updateValue(to, forKey: "to")
            }else {
                dict.updateValue(NSNull(), forKey: "to")
            }
            
            dict.updateValue(elemt[8] ?? "", forKey: "time")
            
            result.append(dict)
        }
        
        closeConnect()
        
        return (true, result)
    }
    
    
    func getReplyCount(topicId:String, commentId:String) -> Int {
        
        if topicId.isNull() || commentId.isNull() {
            return 0
        }
        
        let sql = "select * from t_topic_comment_reply where topicId = \(topicId) and commentId = \(commentId)"
        
        if mySql.query(statement: sql) == false {  return 0 }
        guard let results = mySql.storeResults() else { return 0 }
        return results.numRows()
    }
    
    /// 插入
    func insertCommnetReply(request : HTTPRequest) -> (Bool,String) {
        let topicId = request.param("topicId")
        if topicId.isNull() {
            return (false, "topicId 不能为空")
        }
        
        guard postSQLManager.checkup(topicId: topicId) else {
            return (false, "该内容可能已被删除")
        }
        
        let commentId = request.param("commentId")
        if commentId.isNull() {
            return (false, "commentId 不能为空")
        }
        
        guard commentSQLManager.checkup(tpoicId: topicId) else {
            return (false, "该评论可能已被删除")
        }
        
        let text = request.param("text")
        if text.isNull() {
            return (false, "内容不能为空")
        }
        
        let fromId = request.param("fromId")
        let fromName = request.param("fromName")
        if fromId.isNull() || fromName.isNull() {
            return (false, "发送者不能为空")
        }
        let toId = request.param("toId")
        let toName = request.param("toName")
        if toId.isNull() || fromName.isNull() {
            return (false, "接收者不能为空")
        }
        
        let time = String.time()
        guard connect() else {
            return (false, "操作失败")
        }
        //topicId TEXT, text TEXT, fromId TEXT, fromName TEXT, toId TEXT, toName TEXT, type INT, time TEXT
        let sql = "INSERT INTO t_topic_comment_reply (topicId,commentId,text,fromId,fromName,toId,toName,time) VALUES (\(topicId), '\(commentId)', '\(text)', '\(fromId)', '\(fromName)', '\(toId)', '\(toName)', '\(time)')"

        if mySql.query(statement: sql) == true {
            CTLog("INSERT success")

            if toId == fromId {
                return (true, "操作成功")
            }

            let content = request.param("content")
            messageSQLManager.insert(userId: toId,
                                     topicId: topicId,
                                     commentId: commentId,
                                     message: text,
                                     content: content,
                                     fromId: fromId,
                                     fromName: fromName,
                                     type: 2, time: time)
            
        }else {
            CTLog("INSERT error: " + mySql.errorMessage())
        }
        
        closeConnect()
        return (true, "操作成功")
    }
    
   
}
