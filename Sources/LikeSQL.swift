//
//  LikeSQL.swift
//  CTServer
//
//  Created by 任玉祥 on 2017/10/25.
//

import Foundation
import PerfectHTTP

/// 赞 
class DiscoverTopicLikeManager: DiscoverManager {
    override init() {
        super.init()
        guard connect() else { return }
        
        let sql = "CREATE TABLE IF NOT EXISTS t_topic_like (likeId INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT, topicId TEXT, userId TEXT, userName TEXT, time TEXT)"
        
        let success = mySql.query(statement: sql)
        if success {
            CTLog("创建成功")
        }else{
            CTLog("创建失败: " + mySql.errorMessage())
        }
        
        closeConnect()
    }
    
    
    /// 获取赞
    func getTopicLike(topicId:String?) -> [[String: Any]] {
        
        if topicId == nil || topicId!.isNull() || !connect() {
            return []
        }
        
        let sql = "select * from t_topic_like where topicId = \(topicId!) order by time desc"
        if mySql.query(statement: sql) == false {
            closeConnect()
            return []
        }
        
        guard let results = mySql.storeResults() else {
            closeConnect()
            return []
        }
        
        var arr = [[String:Any]]()
        results.forEachRow { (element) in
            var dict = [String:Any]()
            dict.updateValue(element[0] as Any, forKey: "id")
            dict.updateValue(element[1] as Any, forKey: "topicId")
            dict.updateValue(element[4] as Any, forKey: "time")
            
            dict.updateValue(element[2] as Any, forKey: "userId")
            dict.updateValue(element[3] as Any, forKey: "userName")
            
            arr.append(dict)
        }
        
        
        closeConnect()
        return arr
    }
    
    
    /// 更新
    func updataLike(request:HTTPRequest) -> (status:Int, like: Any, msg:String) {
        
        let topicId = request.param("topicId")
        if topicId.isNull() {
            return (-1, NSNull(), "topicId 不能为空")
        }
        
        let userId = request.param("userId")
        let userName = request.param("userName")
        if userId.isNull() ||
            userName.isNull() {
            return (-1, NSNull(), "userId 不能为空")
        }
        
        guard connect() else {
            return (-1, NSNull(), "请求失败")
        }
        
        let sql = "select * from t_topic_like where topicId = \(topicId) and userId = \(userId)"
        
        if mySql.query(statement: sql) == false{
            closeConnect()
            return (-1, NSNull(), "操作失败")
        }
        
        
        guard let results = mySql.storeResults() else {
            closeConnect()
            return (-1, NSNull(), "操作失败")
        }
        
        if results.next() != nil {
            let sql = "delete from t_topic_like where topicId = \(topicId) and userId = \(userId)"
            if mySql.query(statement: sql) {
                closeConnect()
                return (1, ["like":false], "操作成功")
            }
        }else {
            let time = String.time()
            let sql = "insert into t_topic_like (topicId, userId, userName, time) VALUES (\(topicId), \(userId), '\(userName)', '\(time)')"
            if mySql.query(statement: sql) {
                CTLog("INSERT success")
                closeConnect()
                
                let owner = request.param("ownerId")
                let token = loginSQLManager.getDeviceToken(userId: owner)
                pushManager.pushDiscover(token: token, title: nil, conent: userName+"赞了你的动态")
                return (1, ["like":true], "操作成功")
            }
        }
        
        closeConnect()
        return (-1, NSNull(), "操作失败")
    }
    
}
