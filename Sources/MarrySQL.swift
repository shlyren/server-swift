//
//  MarrySQL.swift
//  CTServer
//
//  Created by 任玉祥 on 2018/6/12.
//

import Foundation
import PerfectHTTP

class MarrySQLManager: JiaQiManager {
    override init() {
        super.init()
        guard connect() else { return }
        
        let sql = "CREATE TABLE IF NOT EXISTS t_marry_people (id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT, name TEXT, phone TEXT, count TEXT, text TEXT, createDate TEXT, updateDate TEXT)"
        
        if mySql.query(statement: sql) {
            CTLog("创建成功")
        }else{
            CTLog("创建失败: " + mySql.errorMessage())
        }
        
        closeConnect()
    }
    
    
    
    func updateContent(request: HTTPRequest) -> Bool {
        let phone = request.param("phone");
        if phone.isNull() {
            return false
        }
        
        guard checkup(phone: phone) else {
            return insertContent(request:request);
        }
        guard connect() else {
            return false
        }
        let name = request.param("name")
        let count = request.param("count")
        let text = request.param("text")
        let updateDate = String.time()
        let sql = "update t_marry_people set name = '\(name)', count = '\(count)', text = '\(text)', updateDate = '\(updateDate)' where phone = \(phone)"
        let success = mySql.query(statement: sql);
       
        closeConnect()
        
        return success
    }
    
    private func insertContent(request: HTTPRequest) -> Bool {
     
        guard connect() else { return false }
        
        let name = request.param("name")
        let phone = request.param("phone")
        let count = request.param("count")
        let text = request.param("text")
        let createDate = String.time()
        
        let sql = "insert into t_marry_people (name, phone, count, text, createDate, updateDate) values ('\(name) ', '\(phone)', '\(count)', '\(text)', '\(createDate)', '\(createDate)')"
        let success = mySql.query(statement: sql);
        
        closeConnect();
        return success;
    }
    
    private func checkup(phone: String) -> Bool {
       
        guard connect() else { return false }
        let sql = "select phone from t_marry_people where phone = \(phone)"
        if mySql.query(statement: sql) == false{
            closeConnect()
            return false
        }
        
        let item = mySql.storeResults()?.next();
        closeConnect()
        return item != nil;
    }
    
}
