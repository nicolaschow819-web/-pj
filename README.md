# PinchSplatAR (iPhone 15 隔空手势召唤高斯泼溅空间)

## 📌 项目概述
专为 iPhone 15（iOS 17+）打造的单机 AR 空间漫游应用：
- **实时 AR 空间锚定**：采用 ARKit 6DoF 视觉惯性里程计，将高斯泼溅场景锁死在真实三维物理空间。
- **隔空捏合手势触发**：利用 Apple Vision 框架检测后置摄像头视野内的手部关键点（食指与拇指），实时判定捏合动作，多帧去抖防误触。
- **空间召唤缓动**：捏合触发瞬间在视线前方 1.0 米处生成锚点，高斯点云以 Ease-Out 缓动弹性膨胀展开。
- **单机实时录屏**：内置 ReplayKit 屏幕录制，直接输出实景与 3DGS 混合的第一人称视频。

---

## 🛠️ Mac + Xcode 部署指南

### 1. 新建工程或导入源码
1. 在 Mac 上打开 **Xcode**，点击 **Create New Project** -> 选择 **iOS / App**。
2. 配置参数：
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Minimum Deployments**: iOS 17.0+
3. 将本项目 `App/`, `Views/`, `AR/`, `Gesture/`, `Renderer/`, `Recorder/` 以及 `Resources/` 拖入 Xcode 项目导航栏中。
4. 在项目的 `Info.plist` 中添加相机、相册与麦克风权限（参考本项目 `Info.plist`）。

### 2. 引入 Metal 渲染依赖
在 Xcode 顶部菜单选择：
`File` -> `Add Package Dependencies...` -> 输入开源高斯渲染库：
`https://github.com/scier/MetalSplatter`
点击添加依赖到主 App Target。

### 3. 连接 iPhone 15 真机运行
1. 用 Type-C 数据线将 iPhone 15 连接到 Mac。
2. 在 Xcode 顶部设备栏中选择你的 iPhone 15。
3. 进入 `Signing & Capabilities`，勾选 `Automatically manage signing`，登录你的 Apple ID（免费个人证书即可）。
4. 点击 **Run (Cmd + R)** 编译并安装到手机。

---

## 🎯 最佳体验技巧
1. **手势操作**：打开 App 后，将手伸到手机后置镜头前 **30cm ~ 50cm** 处（自然伸入手指），食指与拇指轻轻捏合一下，即可看到空间瞬间爆发展开。
2. **走动漫游**：场景召唤后已固定在房间物理坐标中，你可以拿着手机直接朝女生走过去、围绕书桌侧面半圈、蹲下或抬头，沉浸式感受“走进照片”的真实三维纵深！
3. **录屏**：点击右下角录屏圆纽，开始第一人称视角的 AR 录制。
