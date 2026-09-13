# 盲盒任务 (MysteryBoxApp)

一款将「任务管理 + 随机盲盒 + 积分 + 角色卡收藏 + 轻度游戏化」结合的 iPhone 应用。
原生 iOS（SwiftUI）实现，本地数据存储（`FileManager` + JSON），无需服务器、无需 App Store。

## 技术栈
- SwiftUI + Swift 5.9，部署目标 iOS 16.0
- 纯本地存储（文档目录 `mysterybox_data.json`）
- 项目由 [xcodegen](https://github.com/yonaskolb/XcodeGen) 从 `project.yml` 生成 Xcode 工程
- CI 由 GitHub Actions 在 macOS runner 上 `xcodebuild` 出 `.ipa`，Windows 端用 Sideloadly 用个人 Apple ID 重签安装

## 目录结构
```
MysteryBoxApp/
├── project.yml              # xcodegen 配置
├── Info.plist
├── Sources/
│   ├── Models/AppModels.swift
│   ├── Services/            # DataStore / BoxEngine / DefaultData
│   ├── ViewModels/          # (本版逻辑集中在 DataStore)
│   └── Views/               # 盲盒 / 任务中心 / 卡片收藏 / 设置
├── Resources/
│   ├── Assets.xcassets      # 图标 / 强调色
│   └── Characters/          # 角色卡图片 char_001~012.webp
└── .github/workflows/build.yml
```

## 本地运行（在 Mac 上）
```bash
brew install xcodegen
cd MysteryBoxApp
xcodegen generate          # 生成 MysteryBoxApp.xcodeproj
open MysteryBoxApp.xcodeproj
```
选择真机或模拟器设备 → ▶ Run。首次运行会创建 `DataStore` 默认数据。

## 构建并安装到 iPhone（零成本方案）
1. 在本机（Windows）写好代码并提交到 GitHub（公开仓库 macOS 构建分钟无限免费；私有仓库每月 2000 分钟）。
2. GitHub Actions 自动在 `push` 到 `main` 时构建，产出 `MysteryBoxApp.ipa` 构建产物。
3. 在 Windows 下载该 `.ipa`，打开 [Sideloadly](https://sideloadly.io/)：
   - 拖入 `.ipa`，填入你的 Apple ID；
   - 连接 iPhone（需同一 Wi-Fi 或 USB）；
   - 点击 Start，等待安装完成。
4. iPhone 上首次打开需在 `设置 → 通用 → VPN与设备管理` 信任你的 Apple ID 开发者证书。
5. 个人签名有效期 7 天，过期后重新下载最新 `.ipa` 用 Sideloadly 重装即可。

> 说明：CI 产出的是**未签名** IPA，由 Sideloadly 在你本机用个人 Apple ID 重签，
> 因此仓库里 `CODE_SIGNING_ALLOWED=NO`，无需任何签名证书即可构建。

## 功能对照（需求 V1 MVP）
- [x] 4 个 Tab：盲盒 / 任务 / 卡片 / 设置
- [x] 分类切换（任务 / 惩罚 / 自定义）
- [x] 1~9 编号、3×3 九宫格、同轮不重复
- [x] 开盒动画（聚焦→充能→解锁→开盖→闪光→MYSTERY REVEAL→角色卡升起翻转→任务结果）
- [x] 开启后保留空盒、✦ 重制盲盒 ✦ 重新生成
- [x] 任务/角色独立随机、稀有度 N/R/SR/SSR 加权抽取
- [x] 重复卡自动转为积分
- [x] 任务状态机：执行中 / 待完成 / 已完成 / 超时 / 已跳过
- [x] 执行 / 挂起 / 提交 / 跳过（消耗积分）/ 超时扣分
- [x] 卡片收藏（已收集显示 + 未收集剪影）
- [x] 设置：分类管理、任务库增删改、卡片查看
- [x] 数据管理：导出 JSON / 导入 JSON / 恢复默认 / 清空

## 注意：角色素材版权与合规
`Resources/Characters` 中的图片为参考素材，涉及真人肖像与较大尺度。
正式发布前请替换为自有/已授权素材或 AI 生成的半写实插画，并自行确认版权与内容合规。
