# Perfect-CouchDB [English](README.md)

[![Perfect logo](http://www.perfect.org/github/Perfect_GH_header_854.jpg)](http://perfect.org/get-involved.html)

[![Perfect logo](http://www.perfect.org/github/Perfect_GH_button_1_Star.jpg)](https://github.com/PerfectlySoft/Perfect)
[![Perfect logo](http://www.perfect.org/github/Perfect_GH_button_2_Git.jpg)](https://gitter.im/PerfectlySoft/Perfect)
[![Perfect logo](http://www.perfect.org/github/Perfect_GH_button_3_twit.jpg)](https://twitter.com/perfectlysoft)
[![Perfect logo](http://www.perfect.org/github/Perfect_GH_button_4_slack.jpg)](http://perfect.ly)


[![Swift 3.0](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platforms OS X | Linux](https://img.shields.io/badge/Platforms-OS%20X%20%7C%20Linux%20-lightgray.svg?style=flat)](https://developer.apple.com/swift/)
[![License Apache](https://img.shields.io/badge/License-Apache-lightgrey.svg?style=flat)](http://perfect.org/licensing.html)
[![Twitter](https://img.shields.io/badge/Twitter-@PerfectlySoft-blue.svg?style=flat)](http://twitter.com/PerfectlySoft)
[![Join the chat at https://gitter.im/PerfectlySoft/Perfect](https://img.shields.io/badge/Gitter-Join%20Chat-brightgreen.svg)](https://gitter.im/PerfectlySoft/Perfect?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Slack Status](http://perfect.ly/badge.svg)](http://perfect.ly) [![GitHub version](https://badge.fury.io/gh/PerfectlySoft%2FPerfect-CURL.svg)](https://badge.fury.io/gh/PerfectlySoft%2FPerfect-CURL)

## Apache CouchDB 数据库连接器

**⚠️注意⚠️：该项目仍处于ß测试状态**

该项目允许通过Perfect连接到[Apache CouchDB](http://couchdb.apache.org)数据库。

完整文档请查阅[http://www.perfect.org/docs/CouchDB.html](http://www.perfect.org/docs/CouchDB.html)并选择中文🇨🇳

本项目采用SPM软件包管理器进行编译，是Perfect项目的一个组成部分[Perfect](https://github.com/PerfectlySoft/Perfect)，可以独立运行，并不需要其他Perfect的组件。

请确定您的计算机上安装了Swift 3.0以上工具集。

## 应用范例

```swift
var test = CouchDB()
var auth = CouchDBAuthentication("perfect", "perfect", auth: .basic)

test.connector.port = 5984
test.authentication = auth
let code = test.databaseCreate("testdb")

let dataSubmit = ["one":"ONE","two":"TWO"]
do {
	let (addCode, response) = try test.addDoc("testdb",doc: dataSubmit)
	print(addCode)
	print(response)
} catch {
	print(error)
}

```


## 编译

请在Package.swift 文件中追加依存关系：

```
.Package(url: "https://github.com/PerfectlySoft/Perfect-CouchDB.git", majorVersion: 1)
```

### 问题报告、内容贡献和客户支持

我们目前正在过渡到使用JIRA来处理所有源代码资源合并申请、修复漏洞以及其它有关问题。因此，GitHub 的“issues”问题报告功能已经被禁用了。

如果您发现了问题，或者希望为改进本文提供意见和建议，[请在这里指出](http://jira.perfect.org:8080/servicedesk/customer/portal/1).

在您开始之前，请参阅[目前待解决的问题清单](http://jira.perfect.org:8080/projects/ISS/issues).

## 更多信息
关于本项目更多内容，请参考[perfect.org](http://perfect.org).
