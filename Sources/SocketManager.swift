//
//  SocketManager.swift
//  CTServer
//
//  Created by 任玉祥 on 2017/10/26.
//

import Foundation
import PerfectLib
import PerfectWebSockets
import PerfectHTTP

let chatManager = ChatSQL.init()

class SocketManager {
    
    private let handler = EchoHandler.init();
    
    
    func makeSocketRoutes() -> Routes {
        var routes = Routes()
        routes.add(method: .get, uri: "/chat", handler: {request, response in
            self.requestHandler(request: request, response: response)
        })
        return routes
    }

    func socketRequest(data: [String:Any]) throws -> RequestHandler {
        return { request, response in
            self.requestHandler(request: request, response: response)
        }
    }
    
    private func requestHandler(request: HTTPRequest, response: HTTPResponse) {
        WebSocketHandler(handlerProducer: {
            (request: HTTPRequest, protocols: [String]) -> WebSocketSessionHandler? in
            guard protocols.contains("chat") else { return nil }
            return self.handler
        }).handleRequest(request: request, response: response)
        //response.completed() // 这里不注释掉, 每次连接后会秒断
    }
}


private class EchoHandler: WebSocketSessionHandler {
    
    let socketProtocol: String? = "chat"
    var sockets = [String: WebSocket]() //保存所有的连接者
    
    func handleSession(request: HTTPRequest, socket: WebSocket) {
        
        socket.readStringMessage { msg, op, fin in
            let userId = request.param("userId")
            if userId.isNull() { return }
            
            if op == .invalid {
                self.sockets.removeValue(forKey: userId)
                CTLog("\nuserId:" + userId + " 已退出 >>> 当前登录数: \(self.sockets.count)")
                return;
            }
            
            guard let string = msg else {
                self.handleSession(request: request, socket: socket)
                return
            }
            
            self.setupData(request: request, socket: socket, string: string)
        }
    }
    
    
}


private extension EchoHandler {
    
     func setupData(request: HTTPRequest, socket: WebSocket, string: String) {
        
        let userId = request.param("userId")
        
        guard let url = URL.init(string: string) else {
            CTLog("socket count:\(self.sockets.count)")

            guard let decoded = try? string.jsonDecode() as! [String: Any] else {
                handleSession(request: request, socket: socket)
                return
            }
            guard let fromId = decoded["userId"] as? String else {
                handleSession(request: request, socket: socket)
                return
            }
            
            if let toSocket = self.sockets[fromId] {
                
                toSocket.sendStringMessage(string: string, final: true, completion: {
                    self.handleSession(request: request, socket: socket)
                })
                
            }else{
                
                chatManager.save(data: string, userId: fromId)
                let user = decoded["user"] as? [String: Any]
                let title = user?["userName"] as? String
                let content = decoded["text"] as? String
                let token = loginSQLManager.getDeviceToken(userId: fromId)
                pushManager.pushChat(token: token, title: title, conent: content)
                handleSession(request: request, socket: socket)
            }
            
            return
        }
        
        if url.scheme != "ctchat" {
            handleSession(request: request, socket: socket)
            return
        }
        
        if url.host == "clientlogin" {
            
            if let so = self.sockets[userId] {
                let msg = "ctchat://server?code=-1&title=您已强制下线&message=您的帐号在其他设备登录, 如不是本人操作请尽快修改密码"
                so.sendStringMessage(string: msg, final: true, completion: {
                    self.handleSession(request: request, socket: socket)
                });
                so.close()
                self.sockets.removeValue(forKey: userId)
                loginSQLManager.removeDeviceToken(userId: userId)
                
                // 账号在其他设备登录后需要重新上传新的设备的push token
                let newSo = "ctchat://server?code=1000&title=请上传推送Token&message=请上传推送Token,否则可能导致推送失效"
                socket.sendStringMessage(string: newSo, final: true, completion: {
                    self.handleSession(request: request, socket: socket)
                })
                
            }
            
            self.sockets.updateValue(socket, forKey: userId)
            CTLog("\nuserId:" + userId + " 已登录 >>> 当前登录数: \(self.sockets.count)")

            let arr = chatManager.getData(userId: userId);
            if arr.count > 0 {
                if let data = try? arr.jsonEncodedString() {
                    socket.sendStringMessage(string: data, final: true, completion: {
                        self.handleSession(request: request, socket: socket)
                        chatManager.clearData(userId: userId)
                    })
                }
            } else {
                handleSession(request: request, socket: socket)
            }
            
        }else if url.host == "clientlogout" {
            
            handleSession(request: request, socket: socket)
            if let so = sockets[userId] {
                so.close()
            }
        }
        
    }
    
}







