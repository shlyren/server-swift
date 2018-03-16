//
//  Package.swift
//  PerfectTemplate
//
//  Created by Kyle Jessup on 4/20/16.
//	Copyright (C) 2016 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PackageDescription

let package = Package(
	name: "CTServer", // 项目名称, 即编译后的二进制文件名称
	targets: [],
	dependencies: [
        .Package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", majorVersion: 2), // http 服务
        .Package(url: "https://github.com/PerfectlySoft/Perfect-MySQL.git", majorVersion: 3), // 数据库
        .Package(url:"https://github.com/PerfectlySoft/Perfect-Notifications.git",  majorVersion: 2, minor: 0), // iOS推送
        .Package(url:"https://github.com/PerfectlySoft/Perfect-WebSockets.git", majorVersion: 2), // 及时通讯
    ]
)

