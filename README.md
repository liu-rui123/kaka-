# 卡卡捕猎场

一款给真实猫咪玩的 iPhone/iPad 互动追逐游戏。移动目标由 SpriteKit 实时绘制，猫爪触碰不会像视频播放器一样导致暂停。

## 已实现功能

- iPhone 与 iPad、横屏与竖屏，最低 iOS/iPadOS 16。
- 老鼠、小鱼、蝴蝶、甲虫、毛线球、羽毛六种目标，可多选并同时出现 1–3 个。
- 每种目标独立调节大小和速度。
- 从相册选择照片，拖动缩放并裁剪成目标脸图；照片只保存在本机。
- 命中时显示扩散光圈、粒子与目标逃跑效果，并播放短促打击声。
- 移动过程中间歇播放与打击声不同的柔和吸引声，同时显示淡色提示波纹。
- 游戏中普通触摸不会暂停；右上角长按 3 秒才会打开控制菜单。
- 游戏期间保持屏幕常亮，并提示配合系统“引导式访问”。
- 使用卡卡照片制作的 iPhone/iPad 完整 AppIcon。

## 从 Windows 使用 GitHub 构建

本仓库使用 `project.yml` 描述 Xcode 工程。GitHub Actions 会在 macOS runner 上安装 XcodeGen、生成工程、执行测试并输出未签名 IPA。

工程使用 Xcode 的 Swift 5 语言模式，构建工具版本由 GitHub macOS runner 中的稳定版 Xcode 提供。

1. 在 GitHub 新建仓库，把本目录全部文件推送到 `main` 或 `master` 分支。
2. 打开仓库的 **Actions** 页面，选择 **Build iOS IPA**。推送后会自动构建，也可以点 **Run workflow** 手动触发。
3. 构建成功后，在运行记录底部下载 `KakaHunt-unsigned-IPA` artifact。
4. 解压 artifact 获得 `KakaHunt-unsigned.ipa`，再使用你有权使用的证书和描述文件通过全能签等工具重签、安装。

未签名 IPA 不能直接在 iOS 上运行；GitHub 工作流不会读取或保存你的签名证书。

## 在 Mac 上打开

安装 XcodeGen 后，在仓库根目录执行：

```bash
brew install xcodegen
xcodegen generate
open KakaHunt.xcodeproj
```

## 使用提示

- 建议为设备安装屏幕保护膜，并在主人看护下使用。
- 可在“设置 → 辅助功能 → 引导式访问”中启用系统锁定功能；进入游戏后连按三次侧边键启动。
- 吸引声每隔约 2.2–4.2 秒播放一次，不会由多个目标持续叠加。如果猫咪对声音敏感，可在首页关闭音效。

## 项目结构

- `KakaHunt/Views`：设置、照片裁剪和全屏游戏界面。
- `KakaHunt/Game`：移动目标、命中特效以及两类合成音效。
- `KakaHunt/Models`、`Services`：设置模型、本地持久化和脸图存储。
- `.github/workflows/build-ios.yml`：测试并生成未签名 IPA。
