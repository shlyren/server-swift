//
//  LoginSQL.swift
//  CTServer
//
//  Created by 任玉祥 on 2017/10/25.
//

import Foundation
import PerfectHTTP

///mark - 登录
class DiscoverLoginManager: DiscoverManager {
    
    enum ValueType {
        case Token
        case UserId
        var key: String {
            switch self {
            case .Token: return "token"
            case .UserId: return "userId"
            }
        }
    }
    
    override init() {
        super.init()
        guard connect() else { return }
        
        let sql = "create table if not exists t_topic_token (id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT, userId TEXT, token TEXT, deviceToken TEXT, time TEXT)"
        
        if mySql.query(statement: sql) {
            CTLog("创建成功")
        }else{
            CTLog("创建失败: " + mySql.errorMessage())
        }
        closeConnect()
    }
    
    
    /// 保存用户登录koken
    ///
    /// - Parameter userId: 用户id
    /// - Returns: token
    func saveToken(userId: String) -> String? {
        
        if userId.isNull() { return nil }
        
        let time = String.time()
        let token = StringProxy.init(proxy: userId+time).md5
        var sql : String!
        
        if getToken(userId: userId) == nil {
            sql = "insert into t_topic_token (userId, token, time) values ('\(userId)', '\(token)', '\(time)')"
        }else {
            sql = "update t_topic_token set token = '\(token)',time = '\(time)' where userId = '\(userId)'"
        }
        
        guard connect() else { return nil }
        if mySql.query(statement: sql) {
            CTLog("saveToken success")
        }else {
            CTLog("saveToken error: " + mySql.errorMessage())
        }
        closeConnect()
        return token
    }
    
    
    /// 保存 iOS push token
    ///
    /// - Parameter request: http请求体,
    /// - Returns: 是否成功
    func saveDeviceToken(request: HTTPRequest) -> Bool {
        
        let userId = request.param("userId")
        if userId.isNull() { return false }
        let deviceToken = request.param("deviceToken")
        if deviceToken.isNull() { return false }
        guard connect() else { return false }
        let sql = "update t_topic_token set deviceToken = '\(deviceToken)' WHERE userId = '\(userId)'"
        let success = mySql.query(statement: sql)
        if success == false {
            CTLog(mySql.errorMessage())
        } else {
            CTLog("saveDeviceToken success")
        }
        closeConnect()
        return success;
    }
    
    func deleteUser(user: String) {
        if user.isNull() { return }
        guard connect() else { return }
        
        let sql = "delete from t_topic_token where userId = \(user)"
        _ = mySql.query(statement: sql)
        closeConnect()
    }
    
    
    /// 获取 push token
    ///
    /// - Parameter userId: 用户id
    /// - Returns: token
    func getDeviceToken(userId:String!) -> String? {
        return getValue(type: .UserId, name: userId)?[2]
    }
    
    
    /// 删除推送token
    ///
    /// - Parameter userId: 用户id
    func removeDeviceToken(userId: String) {

        guard userId.isNull() || connect() else { return }
        let sql = "update t_topic_token set deviceToken='' WHERE userId = '\(userId)'"
        _ = mySql.query(statement: sql)
        closeConnect()
    }
    
    
    /// 通过token删除用户token
    ///
    /// - Parameter token: token
    /// - Returns: 是否成功
    func deleteToken(token: String!) -> Bool {
        return deleteToken(type: .Token, name: token)
    }
    
    /// 通过用户id删除用户token
    ///
    /// - Parameter userId: 用户id
    /// - Returns: 是否成功
    func deleteToken(userId: String!) -> Bool {
        return deleteToken(type: .UserId, name: userId)
    }
    
    
    
    /// 通过token获取用户ID
    ///
    /// - Parameter token: 用户登录token
    /// - Returns: 用户id
    func getUserId(token: String!) -> String? {
        return getValue(type: .Token, name: token)?[0]
    }
    
    /// 通过用户idh获取token
    ///
    /// - Parameter userId: 用户id
    /// - Returns: token
    func getToken(userId: String!) -> String? {
        return getValue(type: .UserId, name: userId)?[1]
    }
    
    
    
    
}


private extension DiscoverLoginManager {
    
    func getValue(type:ValueType!, name:String!) -> [String]? {
        if name == nil || name.isNull() { return nil }
        guard connect() else { return nil }

        let key = type.key
        let sql = "select * from t_topic_token where \(key) = \(name!) order by id desc limit 1"
        if !mySql.query(statement: sql) {
            closeConnect()
            return nil
        }
        
        guard let elemt = mySql.storeResults()?.next() else {
            closeConnect()
            return nil
        }
        var res = [String]()
        res.append(elemt[1] ?? "")
        res.append(elemt[2] ?? "")
        res.append(elemt[3] ?? "")
        closeConnect()
        return res
        
    }
    
    func deleteToken(type: ValueType!, name:String!) -> Bool {
        
        if name == nil || name.isNull() { return false }
        guard connect() else { return false }
        
        let key = type.key
        let sql = "delete from t_topic_token shere \(key) = \(name!)"
        let success = mySql.query(statement: sql)
        closeConnect()
        
        return success
    }
    
    
}
