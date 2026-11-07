# WiFi Radar (Wi-Fi 深度全息频谱雷达)

> 📡 **macOS 原生 120Hz 全息频谱感知、信道拓扑雷达与射频分析工具**  
> 采用 **Swift 6 + SwiftUI + CoreWLAN** 纯原生构建，1:1 像素级复刻 Safari 统一工具栏，零外部第三方依赖。

---

## ✨ 核心特性 (Key Features)

- **⚡ 120Hz ProMotion 动态物理弹簧频谱**：
  - 基于真实 IEEE 802.11 射频抛物线衰减函数实时渲染。
  - 动态 RSSI 物理动量阻尼回弹，支持 2.4 GHz、5.0 GHz 与 6.0 GHz（Wi-Fi 6E/7）多频段无缝切换。
- **🧭 1:1 像素级 Safari 统一沉浸式顶栏**：
  - 深度定制 `NSToolbar`，红黄绿红绿灯完美对齐。
  - 药丸切换器 `[ 频谱图 | 数据列表 | 混合分屏 ]`、高对比度搜索框、历史记录、扫描与全息侧边抽屉。
- **📊 广播报文全息解析**：
  - 深度扫描 BSSID、信道频宽（20/40/80/160 MHz）、信噪比 (SNR)、噪声基底 (Noise Floor)。
  - 解析 Wi-Fi 协议代际（Wi-Fi 4 / 5 / 6 / 6E / 7）与加密类型（WPA2 / WPA3 SAE）。
  - 国别码 Emoji 自动解析（🇨🇳 / 🇺🇸 / 🇯🇵 等）。
- **💾 窗口与分栏尺寸记忆**：
  - 双层持久化机制（`NSWindow.setFrameAutosaveName` + `AppStorage`），无缝保持用户调整后的窗口、侧边栏及右侧抽屉宽度。
- **📤 全量数据导出**：
  - 支持一键导出标准化 CSV 格式与完整原始遥测 JSON 报文。

---

## 🚀 快速开始与构建 (Quick Start & Build)

### 环境需求
- macOS 13.0 (Ventura) 或更高版本 (支持 macOS 14 Sonoma 与 macOS 15 Sequoia)
- Apple Silicon (M1/M2/M3/M4) 或 Intel 架构
- Xcode 15+ 或 Swift 6 工具链

### 本地编译与运行
```bash
git clone https://github.com/Z-tar/WiFiRadar.git
cd WiFiRadar

# 一键编译安装至 /Applications/WiFiRadar.app 并生成 DMG/ZIP 分发包
./build.sh
```

---

## 🛠️ 项目结构 (Architecture)

```text
WiFiRadar/
├── Package.swift                  # Swift Package Manager 配置
├── build.sh                       # 编译构建与 DMG/ZIP 打包脚本
├── make_icon.swift                # 原生高清母版图标生成脚本
├── Resources/
│   ├── AppIcon.icns               # 官方应用图标
│   ├── icon_1024.png              # 1024x1024 高清图标母版
│   └── Info.plist                 # 系统权限与配置
└── Sources/
    ├── main.swift                 # 应用程序独立生命周期与主菜单
    ├── WiFiRadarCore.swift        # CoreWLAN 底层硬件扫描与 120Hz 物理模型
    └── WiFiRadarView.swift        # Safari 像素级统一顶栏与 SwiftUI 渲染界面
```

---

## 📄 开源许可证 (License)

本项目采用 [MIT License](LICENSE) 开源。
