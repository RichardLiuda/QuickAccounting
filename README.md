# QuickAccounting - 快速记账应用

一个基于SwiftUI开发的iOS记账应用，提供简单直观的记账和数据统计功能。

## 功能特点

- 📝 快速记账：支持收入和支出记录
- 📊 数据统计：查看收支统计和分析
- 🏷️ 分类管理：预设多种收支分类
- 📱 现代UI：基于SwiftUI构建的流畅界面
- 🔄 实时同步：与后端服务器实时数据同步

## 技术架构

- 前端框架：SwiftUI
- 状态管理：ObservableObject
- 网络层：URLSession异步请求
- 后端API：RESTful接口
- 数据格式：JSON

## 系统要求

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## 后端服务

应用需要配合后端服务使用，默认后端服务地址为：`http://47.93.96.145:8000`

## 主要功能模块

1. 记账模块（TransactionFormView）
   - 支持添加收入和支出记录
   - 自定义金额、分类和备注

2. 统计模块（StatisticsView）
   - 查看收支统计数据
   - 支持不同时间周期的数据分析

3. 设置模块
   - 服务器配置
   - 应用偏好设置

## 开发说明

项目使用最新的Swift并发特性和SwiftUI框架，采用MVVM架构模式，确保代码的可维护性和可扩展性。 