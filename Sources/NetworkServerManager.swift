//
//  NetworkServerManager.swift
//  CTServer
//
//  Created by 任玉祥 on 2017/9/6.
//

import Foundation
import PerfectLib
import PerfectHTTP
import PerfectHTTPServer

let postSQLManager = DiscoverPostManager.init(); // 发布
let loginSQLManager = DiscoverLoginManager.init(); // 登录
let likeSQLManager = DiscoverTopicLikeManager.init(); // 赞
let commentSQLManager = DiscoverCommentManager.init() // 评论
let replyCommentSQLManager = DiscoverCommentReplyManager.init() // 回复
let messageSQLManager = DiscoverMessageManager.init() // 消息
let pushManager = PushManager.init() // 推送

let jqMarryManager = MarrySQLManager.init();

class NetworkServerManager {
    
//    let server = HTTPServer.init()
    
    init() {
//        server.documentRoot = "webroot"      //根目录
//        server.serverPort = 8080 // 端口
        
//    #if os(Linux) // 服务器(Ubuntu)端使用ssl协议
////        server.serverName = "api.ctoa.yuxiang.ren"
////        let certPath = "/etc/letsencrypt/live/api.ctoa.yuxiang.ren/cert.pem" // 证书
////        let keyPath = "/etc/letsencrypt/live/api.ctoa.yuxiang.ren/privkey.pem" // 私钥
//        server.serverName = "shlyren.com"
//        let certPath = "/etc/nginx/sslkey/shlyren.com/full_chain.pem" // 证书路径
//        let keyPath = "/etc/nginx/sslkey/shlyren.com/private.key" // 私钥路径
//        server.ssl = (certPath, keyPath)
//        server.certVerifyMode = .sslVerifyPeer
//    #endif
        
//        server.addRoutes(makeHttpRoutes())    //路由添加进服务
//        // socket
//        server.addRoutes(SocketManager().makeSocketRoutes())
//        server.setResponseFilters([(Filter404(), .high)])
        
//    #if os(Linux) // 服务器(Ubuntu)端使用ssl协议
//
//        let tlsConfig = [
//            "certPath": "/etc/nginx/sslkey/shlyren.com/full_chain.pem",
//            "verifyMode": "peer",
//            "keyPath": "/etc/nginx/sslkey/shlyren.com/private.key"
//        ]
//        let serverName = "shlyren.com"
//    #else
//        let tlsConfig = NSNull()
//        let serverName = "localhost"
//    #endif
        
        let routes = [
            [
                "uri": "/web/**",
                "handler": staticWebFiles
            ],
            [
                "uri": "/discover/**",
                "handler": HttpRequest
            ],
            [
                "uri": "/marry",
                "handler": HttpRequest
            ],
            [
                "uri": "/chat",
                "handler": SocketManager().socketRequest
            ]
            
        ]
        let filters = [
            [
                "type" : "response",
                "priority" : "high",
                "name" : PerfectHTTPServer.HTTPFilter.contentCompression,
            ]
        ]
        var servers = [
            [
                "name" : "shlyren.com",
                "port" : 80,
                "routes" : routes,
                "filters" : filters
            ]
        ]
    #if os(Linux)
        servers.append([
            "name" : "shlyren.com",
            "port" : 443,
            "routes" : routes,
            "filters" : filters,
            "tlsConfig" : [
                "certPath": "/etc/nginx/sslkey/shlyren.com/full_chain.pem",
                "verifyMode": "peer",
                "keyPath": "/etc/nginx/sslkey/shlyren.com/private.key"
            ]
        ])
    #endif
        do {
            // Launch the servers based on the configuration data.
            try HTTPServer.launch(configurationData: ["servers": servers])
        } catch {
//            fatalError("====") // fatal error launching one of the servers
        }
    }
    
    
   
    
    //MARK: 404过滤
    struct Filter404: HTTPResponseFilter {
        func filterBody(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
            callback(.continue)
        }
        func filterHeaders(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
            if case .notFound = response.status {
                response.setBody(string: "404 Not Found")
                response.setHeader(.contentLength, value: "\(response.bodyBytes.count)")
                callback(.done)
            } else {
                callback(.continue)
            }
        }
        
    }
    
    //MARK: 开启服务
    open func startServer() {
//        do {
//            CTLog("启动HTTP服务器")
//            try server.start()
//        } catch PerfectError.networkError(let err, let msg) {
//            CTLog("网络出现错误：\(err) \(msg)")
//        } catch {
//            CTLog("网络未知错误")
//        }
        
    }
    
}

private extension NetworkServerManager {

    /// 静态web
    func staticWebFiles(data: [String:Any]) throws -> RequestHandler {
        return {
            request, response in
            let path =  request.urlVariables[routeTrailingWildcardKey] ?? "/"
            request.path = path;
            
            // 设置根目录
        #if os(Linux)
            let rootPath = "/root/swift/server-swift/web";
        #else
            let rootPath = "/Users/yuxiang/Desktop/Fline/OA/CTServer/web";
        #endif
            
            let handler = StaticFileHandler(documentRoot: rootPath, allowResponseFilters: true)
            handler.handleRequest(request: request, response: response)
            response.completed();
            
        }
    }
    /// http api
    func HttpRequest(data: [String:Any]) throws -> RequestHandler {
        return {
            request, response in
            response.setHeader(.contentType, value: "application/json") //响应头
            let body = self.getBodyString(request: request)
            response.setBody(string: body)
            response.completed()
            
        }
    }
}

// MARK: - http
private extension NetworkServerManager {
    //MARK: 注册路由
    func makeHttpRoutes() -> Routes {
        var routes = Routes.init()//创建路由器
        //添加http请求监听
        routes.add(uris: ["/discover/**", "/marry"]) { (request, response) in
            response.setHeader(.contentType, value: "application/json") //响应头
            let body = self.getBodyString(request: request)
            response.setBody(string: body)
            response.completed()
        }
       
        // 添加静态web监听
        routes.add(uri: "/web/**") { request, response in
            let path =  request.urlVariables[routeTrailingWildcardKey] ?? "/"
            request.path = path;

            // 设置根目录
            #if os(Linux)
                let rootPath = "/root/swift/server-swift/web";
            #else
                let rootPath = "/Users/yuxiang/Desktop/Fline/OA/CTServer/web";
            #endif
            
            let handler = StaticFileHandler(documentRoot: rootPath, allowResponseFilters: true)
            handler.handleRequest(request: request, response: response)
        }

//        SocketManager().makeSocketRoutes()
        return routes
    }
    
    /// 获取body
    func getBodyString(request: HTTPRequest) -> String {
        
        switch request.path {
            case "/discover/getTopic": // 获取
                return getDiscoverTopic(request: request)
            case "/discover/getTopicDetail": // 获取
                return getDiscoverTopicDetail(request: request)
            case "/discover/postTopic": // 发布
                return postDiscover(request: request)
            case "/discover/deleteTopic": // 删除
                return deleteDiscover(request: request)
            case "/discover/likeTopic": // 点赞
                return likeDiscover(request: request)
            case "/discover/getTopicLike": //  获取赞
                return getTopicLike(request: request)
            case "/discover/commentTopic": // 评论
                return commentTopic(request: request)
            case "/discover/getTopicComment": /// 获取评论
                return getTopicComment(request: request)
            case "/discover/getCommentDetail": /// 获取评论
                return getTopicCommentDetail(request: request)
            case "/discover/replyComment": // 回复评论
                return replyComment(request: request)
            case "/discover/getReplyComment": //  获取回复
                return getReplyComment(request: request)
            case "/discover/getMessage": //  获取消息
                return getMessage(request: request)
            case "/discover/messageRead":
                return messageRead(request:request)
            case "/discover/login": // 登录
                return login(request: request)
            case "/discover/logout": //
                return logout(request: request)
            case "/discover/saveDeviceToken": // 上传push token
                return saveDeviceToken(request: request)
            case "/discover/push": //
                return pushTest(request:request)
            
            
            
            
            case "/marry":
                return marry(request: request);
            default:
                return ResponseBody(status: -1, message: "请求失败", data: "The path '\(request.path)' was not found")
        }
    }
    
}


// MARK: -
// MARK: 登录,相关
private extension NetworkServerManager {
    
    /// 登录 保存登录信息
    func login(request: HTTPRequest) -> String {
        let userId = request.param("userId")
        if let token = loginSQLManager.saveToken(userId: userId) {
            return ResponseBody(status: 1, message: "登录成功", data: token);
        } else {
            return ResponseBody(status: -1, message: "登录失败", data: NSNull());
        }
    }
    /// 登出 删除登录信息
    func logout(request: HTTPRequest) -> String {
        loginSQLManager.deleteUser(user: request.param("userId"))
        return ResponseBody(status: 1, message: "注销成功", data: NSNull());
    }
    
    /// 保存设备信息
    func saveDeviceToken(request: HTTPRequest) -> String {
        if loginSQLManager.saveDeviceToken(request: request) {
            return ResponseBody(status: 1, message: "保存成功", data: NSNull());
        }else {
            return ResponseBody(status: -1, message: "保存失败", data: NSNull());
        }
    }
    
    /// 推送测试
    func pushTest(request: HTTPRequest) -> String {
        let userId = request.param("userId")
        if userId.isNull() {
            return ResponseBody(status: -1, message: "userId不能为空", data: NSNull())
        }
        let token = loginSQLManager.getDeviceToken(userId: userId)
        if token?.isNull() == true {
            return ResponseBody(status: -1, message: "未上传deviceToken", data: NSNull())
        }
        
        var push = PushMode()
        push.token = token
        push.title = "这是一条推送测试信息"
        push.message = "time: \(String.time()) userId: \(userId)\ntoken: \(token!)"
        push.type = -1000
        pushManager.push(model: push)
        
        var dict = [String: String]()
        dict.updateValue(String.time(), forKey: "time")
        dict.updateValue(userId, forKey: "userId")
        dict.updateValue(token!, forKey: "token")
        return ResponseBody(status: 1, message: "推送已发送", data: dict)
    }
    
    
    
}

// MARK: 动态相关
private extension NetworkServerManager {
    /// 发布动态
    func postDiscover(request: HTTPRequest) -> String {
        
        if postSQLManager.insert(request: request) {
            return ResponseBody(status: 1, message: "发送成功", data: NSNull());
        }else{
            let data = "please check up the params, the `userId` is required!"
            return ResponseBody(status: -1, message: "发送失败", data: data);
        }
    }
    
    
    /// 获取动态
    func getDiscoverTopic(request: HTTPRequest) -> String {
        let res = postSQLManager.getTopic(request: request)
        return ResponseBody(status: 1, message: "请求成功", data: res);
    }
    
    func getDiscoverTopicDetail(request: HTTPRequest) -> String {
        let res = postSQLManager.getTopicDetail(topicId: request.param("topicId"))
        return ResponseBody(status: res == nil ? -1 : 1, message: "", data: res)
    }
    /// 删除动态
    func deleteDiscover(request: HTTPRequest) -> String {
        
        let result = postSQLManager.deleteDiscover(request: request)
        if result.0 == true {
            return ResponseBody(status: 1, message: "删除成功", data: NSNull());
        }else{
            return ResponseBody(status: -1, message: "删除失败", data: result.1);
        }
        
    }
}

//MARK: 评论相关
private extension NetworkServerManager {
    
    /// 获取评论
    func getTopicComment(request: HTTPRequest) -> String {
        
        let topicId = request.param("topicId")
        let res = commentSQLManager.getTopicComment(topicId: topicId)
        return ResponseBody(status: 1, message: "请求成功", data: res);
        
    }
    
    func getTopicCommentDetail(request: HTTPRequest) -> String {
        let commentId = request.param("commentId")
        let res = commentSQLManager.getCommentDetail(commendId: commentId)
        return ResponseBody(status: res == nil ? -1 : 1, message: "", data: res)
    }
    
    /// 发布评论
    func commentTopic(request: HTTPRequest) -> String {
        let res = commentSQLManager.insertComment(request: request)
        
        if res.success == true {
            return ResponseBody(status: 1, message: "评论成功", data: res.msg)
        }else {
            return ResponseBody(status: -1, message: res.msg, data: NSNull())
        }
    }
    
    /// 发布回复
    func replyComment(request: HTTPRequest) -> String {
        let res = replyCommentSQLManager.insertCommnetReply(request: request)
        if res.0 == true {
            return ResponseBody(status: 1, message: res.1, data: res.1)
        } else {
            return ResponseBody(status: -1, message: res.1, data: res.1)
        }
    }
    
    /// 获取回复
    func getReplyComment(request: HTTPRequest) -> String {
        let res = replyCommentSQLManager.getCommentReply(request: request)
        if res.0 == false {
            return ResponseBody(status: -1, message:"\(res.1 ?? "")" , data: nil)
        }else{
            return ResponseBody(status: 1, message: "success", data: res.1)
        }
    }
}

//MARK: 赞相关
private extension NetworkServerManager {
    
    /// 获取👍
    func getTopicLike(request: HTTPRequest) -> String {
        
        let topicId = request.param("topicId")
        let res = likeSQLManager.getTopicLike(topicId: topicId)
        return ResponseBody(status: 1, message: "请求成功", data: res);
        
    }
    /// 点👍
    func likeDiscover(request: HTTPRequest) -> String {
        guard postSQLManager.checkup(topicId: request.param("topicId")) else {
            return ResponseBody(status: -1, message: "操作失败", data: NSNull());
        }
        let res = likeSQLManager.updataLike(request: request)
        return ResponseBody(status: res.status, message: res.msg, data: res.like);
    }
}

// MARK: 消息相关
private extension NetworkServerManager {
    
    /// 获取消息
    func getMessage(request: HTTPRequest) -> String {
        let userId = request.param("userId")
        if userId.isNull() {
            return ResponseBody(status: -1, message: "userId不能为空", data: NSNull())
        }
        let res = messageSQLManager.getMessage(request: request)
        return ResponseBody(status: 1, message: "success", data: res)
    }
    
    func messageRead(request: HTTPRequest) -> String {
        let res = messageSQLManager.setMessageRead(request: request)
        return ResponseBody(status: res.0 ? 1 : -1, message: res.1, data: NSNull())
    }
}


private extension NetworkServerManager {
    func marry(request: HTTPRequest) -> String {
        let success = jqMarryManager.updateContent(request: request);
        return ResponseBody(status: success ? 1 : 0, message: success ? "我们已收到您的信息." : "操作失败", data: NSNull())
    }
}



//MARK: - 格式化消息体
private func ResponseBody(status: Int, message: String?, data: Any?) -> String {
    
    var result = Dictionary<String, Any>()
    result.updateValue(status, forKey: "status")
    result.updateValue(message ?? NSNull(), forKey: "message")
    result.updateValue(data as Any, forKey: "result")

    return EcodingString(data: result)
}

