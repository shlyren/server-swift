## Swift Server
一款使用swift构建的socket聊天接口以及简单的api接口, 包含的功能
1. 基于websocket 的聊天组件, 未读消息的保存, 并未进行所有的消息云端保存
2. 社交系统, 包括发布动态, 评论,点赞, 回复评论等等,以及数据的保存,
3. iOS设备的推送服务
4. 支持ssl: https://shlyren.com:8080/discover/getTopic




## 支持平台
1. macOS (Xcode 9.3 beta 4  编译通过 )
2. Ubuntu(16.04.3 LTS) 

## 注意
1. 项目中用到两个database来保存数据, 需要手动创建下, 他们分别是**ct_discover**和**ct_chat**


## 如何使用 

### on Mac
* 需要安装mysql, 安装教程: http://blog.csdn.net/chenshuai1993/article/details/53141985

1. 克隆项目
```bash
git clone https://github.com/shlyren/server-swift.git && cd server-swift
```

2. 构建Xcode 项目, 完成后会有`xcodeproj`后缀的文件
```bash
swift package generate-xcodeproj
```

3. 打开项目,使用Mac编译, 会有一个sql头文件的报错(**Header '/usr/local/include/mysql/mysql.h' not found**), 找到mysql的头文件: 我用brew安装的在**/usr/local/Cellar/mysql/5.7.21/include/mysql/mysql.h**,  用安装包安装的sql位置有点区别,但依然在**/usr/local**目录下
	
	​
### on ubuntu
* 需要安装 swift (我的版本为3.1.1(推荐)), 安装教程: https://swift.org/getting-started/#installing-swift
* 需要安装sql等必要组件, 具体什么我也忘记了, 这个是很早以前搞的, 不想折腾的直接在本地用Xcode测试吧.
* 本人已经搭建Ubuntu服务器, url为: https://shlyren.com:8080/

1. 克隆项目
```bash
git clone https://github.com/shlyren/server-swift.git && cd server-swift
```

2. 编译项目
```bash
swift build
```

3. 运行执行文件
```bash
./.build/debug/CTServer &
```