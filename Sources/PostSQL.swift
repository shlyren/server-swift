//
//  PostSQL.swift
//  CTServer
//
//  Created by 任玉祥 on 2017/10/25.
//

import Foundation
import PerfectHTTP
import PerfectMySQL

/// 发布
class DiscoverPostManager : DiscoverManager {
    
    override init() {
        super.init()
        guard connect() else { return }
        
        let sql = "CREATE TABLE IF NOT EXISTS t_topic_post (topicId INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT, userId TEXT, userName TEXT, text TEXT, locAddress TEXT, locLat TEXT, locName TEXT, loclng TEXT, pics TEXT, smallPics TEXT, time TEXT)"
        
        if mySql.query(statement: sql) {
            CTLog("创建成功")
        }else{
            CTLog("创建失败: " + mySql.errorMessage())
        }
        
        closeConnect()
    }
    
    
    /// 插入
    func insert(request:HTTPRequest) -> Bool {
        
        let userId = request.param("userId")
        if userId.isNull() { return false }
        
        guard connect() else { return false }
        
        let time = String.time()
        let userName = request.param("userName")
        let text = request.param("text")
        let locAddress = request.param("locAddress")
        let locLat = request.param("locLat")
        let locName = request.param("locName")
        let loclng = request.param("loclng")
        let pics = request.param("pics")
        let smallPics = request.param("smallPics")
        
        let sql = "INSERT INTO t_topic_post (userId,userName,text,locAddress,locLat,locName,loclng,pics,smallPics,time) VALUES (\(userId), '\(userName)', '\(text)', '\(locAddress)', '\(locLat)', '\(locName)', '\(loclng)', '\(pics)','\(smallPics)', '\(time)')"
        
        let success = mySql.query(statement: sql)
        if success == false {
            CTLog("INSERT error: " + mySql.errorMessage())
        }else {
            CTLog("INSERT success")
        }
        closeConnect()
        return success
    }
    
    ///
    func checkup(topicId: String!) -> Bool {
        
        if topicId.isNull() {  return false }
        guard connect() else { return false }
        let sql = "select * from t_topic_post where topicId = \(topicId!)"
        guard mySql.query(statement: sql) else {
            CTLog(mySql.errorMessage())
            closeConnect()
            return false
        }
        
        guard let results = mySql.storeResults() else {
            return false
        }
        
        return results.numRows() > 0
    }
    
    /// 获取
    func getTopic(request:HTTPRequest) -> [[String: Any]] {
        
        guard connect() else { return [] }
        
        let topicId = request.param("topicId")
        let size = request.param(name: "size", defaultValue: "10")!
        
        var sql : String
        if topicId.toInt() > 0 {
            sql = "select * from t_topic_post where topicId < \(topicId) order by time desc limit \(size)"
        } else{
            sql = "select * from t_topic_post order by time desc limit \(size)"
        }
        
        if !mySql.query(statement: sql){
            closeConnect()
            return []
        }
        
        var arr = [[String:Any]]()
        mySql.storeResults()?.forEachRow(callback: { (row) in
            arr.append(getTopicDict(element: row))
        })
        
        closeConnect()
        
        return arr
    }
    
    func getTopicDetail(topicId : String) -> [String:Any]? {
        if topicId.isNull() == true { return nil }
        guard connect() else { return nil }
        
        let sql = "select * from t_topic_post where topicId = \(topicId)"
        if mySql.query(statement: sql) == false {
            CTLog(mySql.errorMessage())
            closeConnect()
            return nil
        }
        
        guard let element = mySql.storeResults()?.next() else {
            CTLog(mySql.errorMessage())
            closeConnect()
            return nil
        }
        
        closeConnect()
        return getTopicDict(element: element)
    }
    
    
    
    // 获取topic 内容文字
    func getConetent(topicId:String) -> String {
        guard let dict = getTopicDetail(topicId: topicId) else {
            return ""
        }
        return dict["text"] as! String
    }
    
    /// 删除
    func deleteDiscover(request:HTTPRequest) -> (Bool,String) {

        let topicId = request.param("topicId")
        let userId = request.param("userId")
        
        if topicId.isNull() || userId.isNull() {
            return (false, "参数错误")
        }
        
        guard connect() else {
            return (false, "连接错误")
        }
        
        let sql = "delete from t_topic_post where topicId = \(topicId) and userId = \(userId)"
        let success = mySql.query(statement: sql)
        closeConnect()
        return (success, success ? "删除成功" : "删除失败");
    }
    
}

private extension DiscoverPostManager {
    // 格式化topic
    func getTopicDict(element: [String?]) -> [String:Any] {
        var dict = [String:Any]()
        let topicId = element[0]
        //topicId,userId,userName,text,locAddress,locLat,locName,loclng,pics,time
        dict.updateValue(topicId as Any, forKey: "topicId")
        dict.updateValue(element[3] as Any, forKey: "text")
        dict.updateValue(element[10] as Any, forKey: "time")
        
        /// 用户信息
        var user = [String:Any]()
        user.updateValue(element[1] as Any, forKey: "id")
        user.updateValue(element[2] as Any, forKey: "name")
        dict.updateValue(user, forKey: "user")
        
        /// 位置信息
        let lat = Double(element[5]!)
        let lng = Double(element[7]!)
        if lat != nil && lng != nil && lat! > 0.0 && lng! > 0.0 {
            var loc = [String:Any]()
            loc.updateValue(element[4] ?? "", forKey: "locAddress")
            loc.updateValue(lat!, forKey: "locLat")
            loc.updateValue(element[6] ?? "", forKey: "locName")
            loc.updateValue(lng!, forKey: "locLng")
            dict.updateValue(loc, forKey: "location")
        } else {
            dict.updateValue(NSNull(), forKey: "location")
        }
        
        /// 图片信息
        let pics = element[8]!.components(separatedBy: ",")
        let smallPic = element[9]!.components(separatedBy: ",")
        var picArr = [[String:String]]()
        for index in 0...pics.count-1 {
            let pic = pics[index]
            if pic.length > 0 {
                var picDict = [String:String]()
                picDict.updateValue(pic, forKey: "image")
                picDict.updateValue(smallPic[index], forKey: "smallImage")
                picArr.append(picDict)
            }
        }
        dict.updateValue(picArr, forKey: "pics")
        
        /// 喜欢
        let likes = likeSQLManager.getTopicLike(topicId: topicId)
        dict.updateValue(likes, forKey: "likes")
        dict.updateValue(likes.count, forKey: "likesCount")
        
        /// 评论
        let comments = commentSQLManager.getTopicComment(topicId: topicId)
        dict.updateValue(comments, forKey: "comments")
        dict.updateValue(comments.count, forKey: "commentsCount")
        
        return dict
    }
}
