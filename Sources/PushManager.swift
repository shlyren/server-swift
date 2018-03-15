//
//  PushManager.swift
//  CTServer
//
//  Created by 任玉祥 on 2017/10/24.
//

import Foundation
import PerfectNotifications
import PerfectNet

/// 推送模型
struct PushMode {
    var token : String! // 设配token
    var title : String? // 推送标题
    var message : String? // 推送内容
    var badge : Int? // app 角标
    var sound : String? // 声音
    var type : Int? // 类型
    var data : Any? // 扩展数据
}

struct PushManager {
    
    private let confName = "My configuration name - can be whatever"
    
    init() {
        
        #if os(Linux)
           let cert = "/var/CTPushCert/apns-dev.pem" // 服务器(Ubuntu)推送证书路径
        #else
           let cert = "/Users/yuxiang/Desktop/Fline/OA/iOS/证书/apns-dev.pem"// 本地推送证书路径
        #endif
        
        NotificationPusher.addConfigurationIOS(name: confName, certificatePath: cert)
        NotificationPusher.development = true
    }
    
    
    /// 工作圈推送
    func pushDiscover(token: String?, title: String?, conent: String?) {
        var model = PushMode()
        model.token = token
        model.title = title
        model.message = conent
        model.type = 1001
        push(model: model)
    }
    
    /// 聊天推送
    func pushChat(token: String?, title: String?, conent: String?) {
        var model = PushMode()
        model.token = token
        model.sound = "chat_new_message.m4a"
        model.title = title
        model.message = conent
        model.type = 1002
        push(model: model)
    }
    
    /// 发送推送
    func push(model: PushMode) {
        if model.token == nil || model.token.length < 10 { return }
        CTLog("token: " + model.token)
        var ary = [IOSNotificationItem]()
        ary.append(IOSNotificationItem.alertTitle(model.title ?? "您有一条消息"))
        if model.message != nil {
            ary.append(IOSNotificationItem.alertBody(model.message!))
        }
        ary.append(IOSNotificationItem.sound(model.sound ?? "default"))
        ary.append(IOSNotificationItem.badge(model.badge ?? 1))
        ary.append(IOSNotificationItem.customPayload("type", model.type ?? 0))
        ary.append(IOSNotificationItem.customPayload("data", model.data ?? "null"))
        
        let n = NotificationPusher.init(apnsTopic: "com.fline.CTOA")
        n.pushIOS(configurationName: confName, deviceToken: model.token, expiration: 0, priority: 10, notificationItems: ary) { (res) in
            CTLog("push result: \(res.description)")
        }
    }
}
